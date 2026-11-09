"""Handing a run's failures and evaluation warnings to a coding agent."""

from __future__ import annotations

import os
import shutil
from typing import Callable, NoReturn

from report import Run

AGENTS = ("claude", "codex", "pi")
MAX_HEADLINES = 3

INSTRUCTIONS = (
    "Find the cause of each failure and evaluation warning in this repository and fix it. "
    "A host that was not answering, or did not come back after a reboot, is not a code problem: "
    "say so and move on. Check each fix by evaluating or building the affected host's configuration "
    "on this machine where it can (`.#nixosConfigurations.<Host>.config.system.build.toplevel`, "
    "`.#darwinConfigurations.<Host>.system`). Do not switch, reboot or deploy any host yourself. "
    "When you are done, tell me what you changed and which `fleet {action} <hosts>` to run."
)


def installed(which: Callable[[str], str | None] = shutil.which) -> list[str]:
    return [agent for agent in AGENTS if which(agent)]


def _failure_lines(run: Run) -> list[str]:
    lines: list[str] = []
    for entry in run.failures():
        code = f", exit code {entry.exit_code}" if entry.exit_code is not None else ""
        how = f", {entry.route}" if entry.route else ""
        lines.append(f"- {entry.host}: {entry.phase} {entry.status}{code}{how}.")
        headlines = [p.headline for p in entry.errors[:MAX_HEADLINES]] or [entry.note]
        lines.extend(f"  {h}" for h in headlines if h)
        if entry.log:
            lines.append(f"  Log: {entry.log}")
    return lines


def prompt(run: Run) -> str:
    """The first message for the agent: what ran, what failed and where to read more."""
    revision = f" ({run.revision})" if run.revision else ""
    lines = [
        f"`fleet {run.action}` ran from {run.local_host} at {run.started} on {', '.join(run.hosts)}, "
        f"with the flake at {run.flake_dir}{revision}."
    ]
    if run.failures():
        lines += ["", "What failed:", *_failure_lines(run)]
    warnings = run.warnings()
    if warnings:
        lines += ["", "Evaluation warnings:"]
        for text, hosts in warnings.items():
            first, *rest = text.splitlines()
            lines.append(f"- {', '.join(hosts)}: {first}" + (" (continues in the report)" if rest else ""))
    lines += [
        "",
        f"The full report, with each failure's error output and the end of its log, is {run.directory}/report.md. "
        "Every host's complete log is next to it.",
        "",
        INSTRUCTIONS.format(action=run.action),
    ]
    return "\n".join(lines)


def hand_off(agent: str, run: Run) -> NoReturn:
    """Replace fleet with the agent, started in the flake checkout."""
    if agent not in AGENTS:
        raise ValueError(f"unknown agent {agent!r}")
    if os.path.isdir(run.flake_dir):
        os.chdir(run.flake_dir)
    os.execvp(agent, [agent, prompt(run)])
