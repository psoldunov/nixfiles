#!/usr/bin/env python3
"""Generate or edit images through Codex CLI's built-in image_gen tool.

Each image is one isolated `codex exec` run. It uses an empty temp directory,
a read-only sandbox and no saved session. The relay model gets one instruction:
call image_gen once with the prompt, copied verbatim. Codex writes the PNG to
$CODEX_HOME/generated_images/<thread_id>/, and this script copies it to --out.

Billing goes through the ChatGPT login, never the metered API:
OPENAI_API_KEY is removed from the child environment.

Usage:
  codex_image.py --out hero.png --prompt "..."
  codex_image.py --out hero.png --prompt-file spec.txt --n 3 --size 1920x1080
  codex_image.py --out cutout.png --ref photo.png --transparent --prompt "..."
  echo "..." | codex_image.py --out x.png

Prints one JSON object to stdout. Exit codes: 0 all images OK, 2 partial
success, 1 failure.
Requires: codex (logged in with ChatGPT), python3 >= 3.9, ImageMagick `magick`.
"""

from __future__ import annotations

import argparse
import concurrent.futures as futures
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

MAX_VARIANTS = 4
DEFAULT_TIMEOUT_S = 300
PNG_MAGIC = b"\x89PNG\r\n\x1a\n"
SIZE_RE = re.compile(r"^(\d{2,5})x(\d{2,5})$")

RELAY_TEMPLATE = """You are a non-interactive relay for the image generation tool. Do exactly this:
1. Call the image generation tool exactly once with these arguments:
   - prompt: the full text inside <image_prompt></image_prompt>, copied verbatim. Do not rewrite, shorten, translate or extend it.
   - transparent_background: {transparent}
{refs_line}2. Do not read skill files or any other files, do not run shell commands, do not copy or move files, do not ask questions.
3. Then reply with exactly OK. If the tool failed or is unavailable, reply with ERROR: followed by the exact error message.

<image_prompt>
{prompt}
</image_prompt>
"""


class SkillError(Exception):
    """Failure with a user-facing message and an optional fix hint."""

    def __init__(self, message: str, hint: str | None = None):
        super().__init__(message)
        self.hint = hint


@dataclass(frozen=True)
class Job:
    index: int
    prompt: str
    refs: tuple[str, ...]
    transparent: bool
    model: str | None
    effort: str
    timeout_s: int


@dataclass(frozen=True)
class JobResult:
    index: int
    source: Path | None
    thread_id: str | None
    agent_message: str
    error: str | None
    elapsed_s: float


def codex_home() -> Path:
    return Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))


def child_env() -> dict[str, str]:
    """Copy the environment without API keys, so Codex bills the ChatGPT plan."""
    blocked = {"OPENAI_API_KEY", "CODEX_API_KEY"}
    return {k: v for k, v in os.environ.items() if k not in blocked}


def preflight() -> str:
    """Check codex and magick exist and Codex uses a ChatGPT login. Return the codex version."""
    if shutil.which("codex") is None:
        raise SkillError("codex CLI not found on PATH", "Install it (Whopper ships it via hosts/whopper/modules/packages.nix).")
    if shutil.which("magick") is None:
        raise SkillError("ImageMagick `magick` not found on PATH", "Install imagemagick.")
    status = subprocess.run(["codex", "login", "status"], capture_output=True, text=True, env=child_env())
    combined = (status.stdout + status.stderr).strip()
    if status.returncode != 0 or "chatgpt" not in combined.lower():
        raise SkillError(f"Codex is not logged in with ChatGPT: {combined or 'no output'}", "Run `codex login` and pick Sign in with ChatGPT.")
    version = subprocess.run(["codex", "--version"], capture_output=True, text=True)
    return version.stdout.strip()


def build_relay_prompt(job: Job) -> str:
    refs_line = ""
    if job.refs:
        refs_line = f"   - referenced_image_paths: {json.dumps(list(job.refs))}\n"
    return RELAY_TEMPLATE.format(
        transparent="true" if job.transparent else "false",
        refs_line=refs_line,
        prompt=job.prompt.strip(),
    )


def codex_command(job: Job, workdir: str) -> list[str]:
    cmd = [
        "codex", "exec", "--json", "--ephemeral", "--skip-git-repo-check",
        "--enable", "image_generation",
        "-s", "read-only", "-C", workdir,
        "-c", f'model_reasoning_effort="{job.effort}"',
    ]
    if job.model:
        cmd += ["-m", job.model]
    return cmd + ["-"]


def parse_events(stdout: str) -> tuple[str | None, str, str | None]:
    """Return (thread_id, last agent message, error) from `codex exec --json` output."""
    thread_id, message, error = None, "", None
    for line in stdout.splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        kind = event.get("type")
        if kind == "thread.started":
            thread_id = event.get("thread_id")
        elif kind == "item.completed" and event.get("item", {}).get("type") == "agent_message":
            message = event["item"].get("text", "").strip()
        elif kind in ("turn.failed", "error"):
            detail = event.get("error") or event.get("message") or event
            error = detail.get("message", str(detail)) if isinstance(detail, dict) else str(detail)
    return thread_id, message, error


def find_output(thread_id: str | None) -> Path | None:
    """Return the newest valid PNG in this thread's generated_images folder."""
    if not thread_id:
        return None
    folder = (codex_home() / "generated_images" / thread_id).resolve()
    if not folder.is_dir():
        return None
    pngs = sorted(folder.glob("*.png"), key=lambda p: p.stat().st_mtime, reverse=True)
    for png in pngs:
        with png.open("rb") as handle:
            if handle.read(8) == PNG_MAGIC:
                return png
    return None


def run_job(job: Job) -> JobResult:
    started = time.monotonic()
    workdir = tempfile.mkdtemp(prefix="codex-imagegen-")
    stdout, error = "", None
    try:
        proc = subprocess.run(
            codex_command(job, workdir), input=build_relay_prompt(job), capture_output=True,
            text=True, env=child_env(), timeout=job.timeout_s,
        )
        stdout = proc.stdout
        if proc.returncode != 0:
            error = f"codex exited {proc.returncode}: {proc.stderr.strip()[-500:]}"
    except subprocess.TimeoutExpired as exc:
        stdout = exc.stdout.decode() if isinstance(exc.stdout, bytes) else (exc.stdout or "")
        error = f"timed out after {job.timeout_s}s"
    finally:
        shutil.rmtree(workdir, ignore_errors=True)

    thread_id, message, event_error = parse_events(stdout)
    source = find_output(thread_id)
    if source is None:
        relay_said = message if message and message != "OK" else None
        error = event_error or error or relay_said or "no image was generated"
    else:
        error = None
    return JobResult(job.index, source, thread_id, message, error, round(time.monotonic() - started, 1))


def unique_path(path: Path, force: bool) -> Path:
    """Return path, or a sibling path ending -v2, -v3 and so on, so nothing is overwritten."""
    if force or not path.exists():
        return path
    version = 2
    while True:
        candidate = path.with_name(f"{path.stem}-v{version}{path.suffix}")
        if not candidate.exists():
            return candidate
        version += 1


def magick(*args: str) -> str:
    proc = subprocess.run(["magick", *args], capture_output=True, text=True)
    if proc.returncode != 0:
        raise SkillError(f"magick {' '.join(args[:3])}... failed: {proc.stderr.strip()}")
    return proc.stdout.strip()


def materialize(source: Path, dest: Path, size: tuple[int, int] | None, fit: str) -> None:
    """Copy source to dest, converting the format and resizing to an exact size if requested."""
    dest.parent.mkdir(parents=True, exist_ok=True)
    if size is None and dest.suffix.lower() == ".png":
        shutil.copyfile(source, dest)
        return
    ops: list[str] = [str(source)]
    if size is not None:
        w, h = size
        if fit == "cover":
            ops += ["-resize", f"{w}x{h}^", "-gravity", "center", "-extent", f"{w}x{h}"]
        else:
            ops += ["-resize", f"{w}x{h}", "-background", "none", "-gravity", "center", "-extent", f"{w}x{h}"]
    magick(*ops, str(dest))


def describe(path: Path, transparent: bool) -> dict:
    width, height = (int(v) for v in magick(str(path), "-format", "%w %h", "info:").split())
    info: dict = {"path": str(path), "width": width, "height": height}
    if transparent:
        corners = magick(str(path), "-format", "%[fx:p{0,0}.a+p{w-1,0}.a+p{0,h-1}.a+p{w-1,h-1}.a]", "info:")
        info["alpha_ok"] = float(corners) == 0.0
    return info


def contact_sheet(paths: list[Path], out: Path) -> Path:
    """Tile the variants left to right, in --n order, into one small preview image."""
    sheet = unique_path(out.with_name(f"{out.stem}-sheet.png"), force=False)
    magick("montage", *map(str, paths), "-geometry", "512x512>+12+12", "-tile", f"{len(paths)}x1",
           "-background", "#e8e8e8", "-depth", "8", str(sheet))
    return sheet


def log_history(entry: dict) -> None:
    state = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state"))
    log = state / "codex-imagegen" / "history.jsonl"
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open("a") as handle:
        handle.write(json.dumps(entry) + "\n")


def read_prompt(args: argparse.Namespace) -> str:
    if args.prompt:
        text = args.prompt
    elif args.prompt_file:
        text = Path(args.prompt_file).read_text()
    elif not sys.stdin.isatty():
        text = sys.stdin.read()
    else:
        text = ""
    if not text.strip():
        raise SkillError("empty prompt", "Pass --prompt, --prompt-file, or pipe the prompt on stdin.")
    return text


def validate(args: argparse.Namespace) -> tuple[tuple[str, ...], tuple[int, int] | None]:
    if not 1 <= args.n <= MAX_VARIANTS:
        raise SkillError(f"--n must be between 1 and {MAX_VARIANTS}")
    refs = []
    for ref in args.ref:
        path = Path(ref).expanduser().resolve()
        if not path.is_file():
            raise SkillError(f"reference image not found: {ref}")
        refs.append(str(path))
    size = None
    if args.size:
        match = SIZE_RE.match(args.size)
        if not match:
            raise SkillError(f"--size must look like 1920x1080, got {args.size!r}")
        size = (int(match[1]), int(match[2]))
    if args.transparent and Path(args.out).suffix.lower() in (".jpg", ".jpeg"):
        raise SkillError("JPEG cannot hold transparency", "Use a .png or .webp --out path.")
    return tuple(refs), size


def output_paths(out: Path, n: int, force: bool) -> list[Path]:
    if n == 1:
        return [unique_path(out, force)]
    return [unique_path(out.with_name(f"{out.stem}-{i}{out.suffix}"), force) for i in range(1, n + 1)]


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--out", required=True, help="destination file (.png, .webp, .jpg)")
    parser.add_argument("--prompt", help="image prompt text")
    parser.add_argument("--prompt-file", help="read the prompt from this file")
    parser.add_argument("--ref", action="append", default=[], help="reference or edit-target image; repeatable, order = Image 1, 2, ...")
    parser.add_argument("--transparent", action="store_true", help="ask for a transparent background and verify alpha")
    parser.add_argument("--n", type=int, default=1, help=f"parallel variants of the same prompt, 1-{MAX_VARIANTS}")
    parser.add_argument("--size", help="exact output size WxH, applied locally after generation")
    parser.add_argument("--fit", choices=("cover", "contain"), default="cover", help="how --size reshapes: crop (cover) or pad (contain)")
    parser.add_argument("--model", help="Codex relay model (the image model itself is Codex-managed)")
    parser.add_argument("--effort", default="low", help="relay model reasoning effort")
    parser.add_argument("--timeout", type=int, default=DEFAULT_TIMEOUT_S, help="seconds per image")
    parser.add_argument("--force", action="store_true", help="overwrite --out instead of writing -v2, -v3, ...")
    return parser.parse_args(argv)


def run(args: argparse.Namespace) -> tuple[dict, int]:
    prompt = read_prompt(args)
    refs, size = validate(args)
    version = preflight()
    jobs = [Job(i, prompt, refs, args.transparent, args.model, args.effort, args.timeout) for i in range(args.n)]
    with futures.ThreadPoolExecutor(max_workers=args.n) as pool:
        results = sorted(pool.map(run_job, jobs), key=lambda r: r.index)

    out = Path(args.out).expanduser().resolve()
    destinations = output_paths(out, args.n, args.force)
    images, saved = [], []
    for result, dest in zip(results, destinations):
        if result.error or result.source is None:
            images.append({"error": result.error, "thread_id": result.thread_id, "agent_message": result.agent_message})
            continue
        materialize(result.source, dest, size, args.fit)
        info = describe(dest, args.transparent) | {
            "source": str(result.source), "thread_id": result.thread_id, "elapsed_s": result.elapsed_s,
        }
        images.append(info)
        saved.append(dest)
        log_history({"time": datetime.now(timezone.utc).isoformat(), "codex": version, "prompt": prompt,
                     "refs": list(refs), "transparent": args.transparent, **info})

    report: dict = {"ok": len(saved) == len(results), "images": images}
    if len(saved) > 1:
        report["sheet"] = str(contact_sheet(saved, out))
    code = 0 if report["ok"] else (2 if saved else 1)
    return report, code


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    try:
        report, code = run(args)
    except SkillError as exc:
        report, code = {"ok": False, "error": str(exc), "hint": exc.hint}, 1
    print(json.dumps(report, indent=2))
    return code


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
