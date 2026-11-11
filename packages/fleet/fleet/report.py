"""What a run leaves behind: the errors and evaluation warnings found in each
host's log, report.md and report.json, and the run directories they live in."""

from __future__ import annotations

import datetime
import json
import re
import shutil
from dataclasses import asdict, dataclass, replace
from pathlib import Path

KEEP_RUNS = 30
TAIL_LINES = 60
# The pseudo-host for steps that run on the flake checkout: git, flake.lock, pins.
FLAKE = "flake"
MAX_PROBLEMS = 10
MAX_BLOCK_LINES = 80

_ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]|\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)|\x1b[@-Z\\-_]")
_WARNING = re.compile(r"^\s*(?:evaluation warning|trace: (?:evaluation )?warning):\s*(.*)$")
_ERROR_LINE = re.compile(r"^\s*error:\s*(.*)$")
# Failures from the tools around nix: git, ssh, sudo, Homebrew, mise, the
# NixOS activation script and nixos-rebuild itself.
_OTHER_ERROR = re.compile(
    r"^(?:fatal: |Error: |ERROR[: ]|E: |ssh: |sudo: |mise ERROR)"
    r"|error\(s\) occurred while switching|the following units failed"
    r"|returned non-zero exit status|Permission denied|Connection (?:refused|timed out|closed)"
)


@dataclass(frozen=True)
class Problem:
    headline: str
    detail: str


@dataclass(frozen=True)
class Entry:
    """One step of a run on one host (or on the flake checkout, host "flake")."""

    host: str
    phase: str
    status: str = "ok"  # ok | failed | skipped | interrupted | deferred (this machine's reboot or suspend)
    note: str = ""
    route: str = ""
    exit_code: int | None = None
    seconds: float = 0.0
    commands: tuple[str, ...] = ()
    log: str | None = None
    errors: tuple[Problem, ...] = ()
    warnings: tuple[str, ...] = ()

    @property
    def failed(self) -> bool:
        return self.status in ("failed", "interrupted")


@dataclass(frozen=True)
class Run:
    action: str
    hosts: tuple[str, ...]
    local_host: str
    flake_dir: str
    directory: str
    started: str
    revision: str = ""
    entries: tuple[Entry, ...] = ()
    interrupted: bool = False

    def failures(self) -> list[Entry]:
        return [e for e in self.entries if e.failed]

    def warnings(self) -> dict[str, list[str]]:
        """Each evaluation warning, with the hosts that printed it."""
        found: dict[str, list[str]] = {}
        for entry in self.entries:
            for warning in entry.warnings:
                hosts = found.setdefault(warning, [])
                if entry.host not in hosts:
                    hosts.append(entry.host)
        return found

    def has_problems(self) -> bool:
        return bool(self.failures() or self.warnings())


def clean_line(raw: str) -> str:
    """A terminal line as it reads once drawn: no colour codes, and only what
    the last carriage return left (progress bars redraw with \\r)."""
    text = _ANSI.sub("", raw)
    for part in reversed(text.split("\r")):
        if part.strip():
            return part.rstrip()
    return ""


def find_warnings(lines: list[str]) -> list[str]:
    """Evaluation warnings, with their indented continuation lines, deduplicated."""
    found: list[str] = []
    for i, line in enumerate(lines):
        match = _WARNING.match(line)
        if not match:
            continue
        parts = [match.group(1).strip()]
        for more in lines[i + 1 :]:
            if not more.strip() or not more[0].isspace():
                break
            parts.append(more.strip())
        text = "\n".join(parts)
        if text not in found:
            found.append(text)
    return found


def _error_block(lines: list[str], start: int) -> int:
    """The index just past the nix error block that starts at lines[start]:
    nix indents everything that belongs to an error, blank lines included."""
    end = start + 1
    while end < len(lines) and (not lines[end].strip() or lines[end][0].isspace()):
        end += 1
    while end > start + 1 and not lines[end - 1].strip():
        end -= 1
    return end


def _headline(block: list[str]) -> str:
    """The innermost error message of a block: with --show-trace nix prints
    the frames first and the actual error last."""
    for i in range(len(block) - 1, -1, -1):
        match = _ERROR_LINE.match(block[i])
        if not match:
            continue
        if match.group(1).strip():
            return match.group(1).strip()
        following = [line.strip() for line in block[i + 1 :] if line.strip()]
        return following[0] if following else "error"
    return block[0].strip()


def _cap(block: list[str]) -> str:
    if len(block) <= MAX_BLOCK_LINES:
        return "\n".join(block)
    half = MAX_BLOCK_LINES // 2
    skipped = len(block) - 2 * half
    return "\n".join([*block[:half], f"… {skipped} lines left out, see the log …", *block[-half:]])


def find_errors(lines: list[str]) -> list[Problem]:
    found: list[Problem] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("error:"):
            end = _error_block(lines, i)
            block = lines[i:end]
            problem = Problem(_headline(block), _cap(block))
            i = end
        elif _OTHER_ERROR.search(line):
            problem = Problem(line.strip(), line.strip())
            i += 1
        else:
            i += 1
            continue
        if all(p.headline != problem.headline for p in found):
            found.append(problem)
    return found[:MAX_PROBLEMS]


def tail(text: str, count: int = TAIL_LINES) -> str:
    return "\n".join(text.splitlines()[-count:])


def analyse(entry: Entry, log_text: str) -> Entry:
    """The entry with the warnings its log printed and, when it failed, its errors."""
    lines = log_text.splitlines()
    errors: tuple[Problem, ...] = ()
    if entry.failed:
        errors = tuple(find_errors(lines))
        if not errors:
            code = entry.exit_code
            headline = entry.note or (f"exited with code {code}" if code is not None else "failed")
            errors = (Problem(headline, tail(log_text, 20)),)
    return replace(entry, errors=errors, warnings=tuple(find_warnings(lines)))


def duration(seconds: float) -> str:
    seconds = int(round(seconds))
    return f"{seconds // 60}m{seconds % 60:02d}s" if seconds >= 60 else f"{seconds}s"


def verdict(run: Run) -> str:
    if run.interrupted:
        return "interrupted"
    failed = {e.host for e in run.failures()}
    hosts = failed - {FLAKE}
    if hosts:
        return f"{len(hosts)} host{'s' if len(hosts) != 1 else ''} failed"
    return "the flake checkout step failed" if failed else "succeeded"


def _fence(text: str) -> list[str]:
    return ["````text", text, "````"]


def _failure_section(entry: Entry) -> list[str]:
    out = [f"## {entry.host}: {entry.phase} {entry.status}", ""]
    if entry.route:
        out.append(f"- How it ran: {entry.route}")
    if entry.exit_code is not None:
        out.append(f"- Exit code: {entry.exit_code}")
    if entry.note:
        out.append(f"- Note: {entry.note}")
    if entry.log:
        out.append(f"- Full log: {entry.log}")
    out.extend(f"- Ran: `{command}`" for command in entry.commands)
    for problem in entry.errors:
        out += ["", f"### {problem.headline}", "", *_fence(problem.detail)]
    if entry.log and Path(entry.log).exists():
        last = tail(Path(entry.log).read_text(errors="replace"))
        out += ["", f"### Last {TAIL_LINES} lines of the log", "", *_fence(last)]
    return out + [""]


def render_markdown(run: Run) -> str:
    out = [
        f"# fleet {run.action}: {verdict(run)}",
        "",
        f"- Started {run.started} on {run.local_host}",
        f"- Hosts: {', '.join(run.hosts)}",
        f"- Flake: {run.flake_dir}" + (f" at {run.revision}" if run.revision else ""),
        f"- Run directory: {run.directory}",
        "",
        "| Host | Step | Result | Time | Note |",
        "|---|---|---|---|---|",
    ]
    for e in run.entries:
        note = (e.errors[0].headline if e.errors else e.note).replace("|", "\\|")
        out.append(f"| {e.host} | {e.phase} | {e.status} | {duration(e.seconds)} | {note} |")
    out.append("")
    for entry in run.failures():
        out += _failure_section(entry)
    warnings = run.warnings()
    if warnings:
        out += ["## Evaluation warnings", ""]
        for text, hosts in warnings.items():
            out.append(f"- {', '.join(hosts)}:")
            out.extend(_fence(text))
        out.append("")
    return "\n".join(out)


def write(run: Run) -> Path:
    directory = Path(run.directory)
    (directory / "report.json").write_text(json.dumps(asdict(run), indent=2) + "\n")
    path = directory / "report.md"
    path.write_text(render_markdown(run))
    return path


def load(directory: Path) -> Run:
    raw = json.loads((directory / "report.json").read_text())
    entries = tuple(
        Entry(
            **{
                **e,
                "commands": tuple(e["commands"]),
                "errors": tuple(Problem(**p) for p in e["errors"]),
                "warnings": tuple(e["warnings"]),
            }
        )
        for e in raw["entries"]
    )
    return Run(**{**raw, "hosts": tuple(raw["hosts"]), "entries": entries})


def runs_dir(state_dir: str) -> Path:
    return Path(state_dir) / "runs"


def new_run_dir(state_dir: str, action: str, now: datetime.datetime) -> Path:
    """A fresh directory for this run's logs, after pruning all but the newest runs."""
    root = runs_dir(state_dir)
    root.mkdir(parents=True, exist_ok=True)
    for old in sorted(p for p in root.iterdir() if p.is_dir())[: -(KEEP_RUNS - 1)]:
        shutil.rmtree(old, ignore_errors=True)
    stem = f"{now:%Y%m%d-%H%M%S}-{action}"
    for n in range(1, 100):
        directory = root / (stem if n == 1 else f"{stem}-{n}")
        try:
            directory.mkdir()
            return directory
        except FileExistsError:
            continue
    raise RuntimeError(f"could not create a run directory under {root}")


def find_run(state_dir: str, name: str | None) -> Path | None:
    """The run directory called <name>, or the newest one that has a report."""
    root = runs_dir(state_dir)
    if name:
        path = Path(name) if "/" in name else root / name
        return path if (path / "report.json").exists() else None
    if not root.is_dir():
        return None
    done = sorted(p for p in root.iterdir() if (p / "report.json").exists())
    return done[-1] if done else None
