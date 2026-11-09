"""fleet: rebuild, update, clean, reboot, sleep and wake this flake's hosts,
collect what went wrong on each, and hand it to an agent to fix."""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

import actions
import agent
import interactive
import inventory
import report
from flow import Execution, Plan, Result
from interactive import Cancelled
from inventory import Config, Host, UsageError
from runner import Console, Jobs, Sink, colour, run_steps

RUN_ACTIONS = ("rebuild", "update", "clean", "reboot", "sleep", "wake")
EXIT_FAILED, EXIT_USAGE, EXIT_INTERRUPTED = 1, 2, 130
HEADLINE_WIDTH = 100
STATUS_MARKS = {"ok": ("ok", "32"), "failed": ("FAILED", "31"), "skipped": ("skipped", "33"), "interrupted": ("stopped", "31")}

HELPS = {
    "rebuild": "switch hosts to the flake as it is, then commit and push",
    "update": "bump flake.lock and the pins, switch hosts (--upgrade-all), commit and push",
    "clean": "collect garbage, prune docker images, brew cleanup",
    "reboot": "restart hosts and wait for them to come back",
    "sleep": "suspend hosts",
    "wake": "wake hosts with Wake-on-LAN and wait for them to answer",
    "status": "show which hosts answer over ssh",
}
REBOOT_HELP = {
    "rebuild": "reboot each host that succeeded, afterwards",
    "update": "reboot each host that succeeded, afterwards",
    "clean": "reboot each host first and clean it once it is back (this machine is cleaned without one)",
}
EPILOG = """\
Hosts go by their flake names, in any case. `all` means every host, minus the
roaming ones (ShackStack and the Macs) that don't answer. Without host names,
fleet asks which ones when it runs on a terminal; with no command at all, it
asks for that too. Each run keeps its logs and a report.md under
~/.local/state/fleet/runs, and `fleet fix` hands the last one to an agent."""


def parser() -> argparse.ArgumentParser:
    top = argparse.ArgumentParser(
        prog="fleet", description=__doc__, epilog=EPILOG, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    sub = top.add_subparsers(dest="command", metavar="COMMAND")
    for name, text in HELPS.items():
        cmd = sub.add_parser(name, help=text, description=text)
        cmd.add_argument("hosts", nargs="*", metavar="HOST")
        if name in ("rebuild", "update", "clean"):
            cmd.add_argument("--reboot", action="store_true", help=REBOOT_HELP[name])
            cmd.add_argument("--wake", action="store_true", help="wake hosts that don't answer first (Wake-on-LAN)")
    shown = sub.add_parser("report", help="print a run's report, the last one by default")
    shown.add_argument("run", nargs="?", help="a run directory, or its name under ~/.local/state/fleet/runs")
    fix = sub.add_parser("fix", help="hand a run's failures and evaluation warnings to an agent")
    fix.add_argument("--agent", choices=agent.AGENTS, help="which agent (asks on a terminal, else claude)")
    fix.add_argument("run", nargs="?", help="a run directory, or its name; the last run by default")
    return top


def capable(cfg: Config, action: str, hosts: list[Host], from_all: bool) -> list[Host]:
    """The hosts the action applies to. Naming one it can't apply to is an
    error; `all` leaves it out."""

    def can(host: Host) -> bool:
        if action == "sleep":
            return host.sleep
        if action == "wake":
            return bool(host.wake_mac) and not cfg.is_local(host)
        return True

    unable = [h.name for h in hosts if not can(h)]
    if unable and not from_all:
        why = "fleet doesn't put it to sleep" if action == "sleep" else "it has no Wake-on-LAN address, or it is this machine"
        raise UsageError(f"can't {action} {', '.join(unable)}: {why}")
    return [h for h in hosts if can(h)]


def ask_plan(cfg: Config, action: str, console: Console, reboot: bool = False, wake: bool = False) -> Plan:
    candidates = capable(cfg, action, list(cfg.hosts), from_all=True)
    if not candidates:
        raise UsageError(f"no host can {action}")
    console.line("Checking which hosts answer…")
    online = inventory.probe(cfg, candidates)
    hosts = interactive.pick_hosts(cfg, action, candidates, online)
    asleep = [h.name for h in hosts if not online[h.name] and h.wake_mac]
    if action in ("rebuild", "update", "clean"):
        if asleep and not wake:
            wake = interactive.confirm(cfg, f"Wake {', '.join(asleep)} first?")
        if not reboot:
            question = "Reboot them first, then clean?" if action == "clean" else "Reboot them afterwards?"
            reboot = interactive.confirm(cfg, question, default=action == "clean")
    return Plan(action, tuple(hosts), from_all=False, reboot=reboot, wake=wake)


def print_summary(result: Result, console: Console) -> None:
    run, stream = result.run, console.stream
    console.line()
    console.line(f"fleet {run.action}: {report.verdict(run)}")
    for e in run.entries:
        text, code = STATUS_MARKS.get(e.status, (e.status, "0"))
        detail = e.errors[0].headline if e.errors else e.note
        if e.warnings:
            count = len(e.warnings)
            detail = (f"{detail}; " if detail else "") + f"{count} evaluation warning{'s' if count != 1 else ''}"
        if len(detail) > HEADLINE_WIDTH:
            detail = detail[: HEADLINE_WIDTH - 1] + "…"
        mark = colour(f"{text:<8}", code, stream)
        console.line(f"  {mark} {e.host:<11} {e.phase:<16} {report.duration(e.seconds):>7}  {detail}")
    console.line(f"Report: {result.report_path}")


def power_local(cfg: Config, action: str, host: Host, console: Console, tty: bool) -> int:
    """Reboot or suspend this machine, the last thing a run does."""
    verb = "Reboot" if action == "reboot" else "Suspend"
    if tty and not interactive.confirm(cfg, f"{verb} {host.name} (this machine) now?"):
        console.line(f"Left {host.name} running.")
        return 0
    with open(os.devnull, "w") as devnull:
        outcome = run_steps(actions.BUILDERS[action](cfg, host, tty), Sink(devnull, console, None), jobs=Jobs(), solo=True)
    return 0 if outcome.ok else EXIT_FAILED


def offer_agent(cfg: Config, result: Result, console: Console, tty: bool) -> None:
    """On a terminal, offer to start an agent on the run's problems; it takes
    over this process, so this returns only when none was picked."""
    chosen = None
    if tty:
        try:
            chosen = interactive.pick_agent(cfg, agent.installed())
        except Cancelled:
            chosen = None
    if chosen is None:
        console.line("Hand these to an agent later with: fleet fix [--agent claude|codex|pi]")
        return
    if result.local_power:
        action, host = result.local_power
        console.line(f"fleet: {host.name} stays up while {chosen} works; run `fleet {action} {host.name}` after.")
    agent.hand_off(chosen, result.run)


def execute(cfg: Config, plan: Plan, console: Console, tty: bool) -> int:
    if not plan.hosts:
        raise UsageError(f"no host to {plan.action}")
    result = Execution(cfg, plan, console).go()
    run = result.run
    print_summary(result, console)
    if run.interrupted:
        return EXIT_INTERRUPTED
    if run.has_problems():
        offer_agent(cfg, result, console, tty)
    code = EXIT_FAILED if run.failures() else 0
    if result.local_power:
        action, host = result.local_power
        code = power_local(cfg, action, host, console, tty) or code
    return code


def run_action(cfg: Config, action: str, args: argparse.Namespace, console: Console, tty: bool) -> int:
    reboot, wake = getattr(args, "reboot", False), getattr(args, "wake", False)
    if args.hosts:
        hosts, from_all = inventory.resolve(cfg, args.hosts)
        plan = Plan(action, tuple(capable(cfg, action, hosts, from_all)), from_all, reboot, wake)
    elif tty:
        plan = ask_plan(cfg, action, console, reboot, wake)
    else:
        raise UsageError(f"name the hosts to {action}, or `all`")
    return execute(cfg, plan, console, tty)


def show_status(cfg: Config, names: list[str], console: Console) -> int:
    hosts, _ = inventory.resolve(cfg, names or ["all"])
    online = inventory.probe(cfg, hosts)
    for host in hosts:
        state = "this machine" if cfg.is_local(host) else ("online" if online[host.name] else "not answering")
        code = "32" if online[host.name] else "33"
        can = [host.kind] + (["sleeps"] if host.sleep else []) + (["Wake-on-LAN"] if host.wake_mac else [])
        console.line(f"{host.name:<12}{colour(f'{state:<15}', code, console.stream)}{', '.join(can)}")
    return 0


def _run_dir(cfg: Config, name: str | None) -> Path:
    found = report.find_run(cfg.state_dir, name)
    if found is None:
        raise UsageError(f"no run {name!r}" if name else f"no runs yet under {report.runs_dir(cfg.state_dir)}")
    return found


def show_report(cfg: Config, name: str | None) -> int:
    print((_run_dir(cfg, name) / "report.md").read_text(), end="")
    return 0


def fix(cfg: Config, name: str | None, chosen: str | None, tty: bool, console: Console) -> int:
    run = report.load(_run_dir(cfg, name))
    if not run.has_problems():
        console.line(f"fleet {run.action} from {run.started} had no failures or evaluation warnings.")
        return 0
    installed = agent.installed()
    if chosen is None:
        chosen = interactive.pick_agent(cfg, installed) if tty else ("claude" if "claude" in installed else None)
    elif chosen not in installed:
        raise UsageError(f"{chosen} is not on PATH")
    if chosen is None:
        console.line(f"No agent picked. The report is {Path(run.directory) / 'report.md'}")
        return 0
    agent.hand_off(chosen, run)


def dispatch(cfg: Config, args: argparse.Namespace, console: Console) -> int:
    tty = sys.stdin.isatty() and sys.stdout.isatty()
    command = args.command
    if command is None:
        if not tty:
            parser().print_help()
            return EXIT_USAGE
        command = interactive.pick_action(cfg)
        args = argparse.Namespace(hosts=[], run=None, agent=None)
    if command == "status":
        return show_status(cfg, args.hosts, console)
    if command == "report":
        return show_report(cfg, args.run)
    if command == "fix":
        return fix(cfg, args.run, args.agent, tty, console)
    return run_action(cfg, command, args, console, tty)


def main(argv: list[str]) -> int:
    if not argv:
        print("fleet: started without its config; run it through the `fleet` wrapper", file=sys.stderr)
        return EXIT_USAGE
    cfg = inventory.load(json.loads(argv[0]))
    args = parser().parse_args(argv[1:])
    try:
        return dispatch(cfg, args, Console())
    except UsageError as error:
        print(f"fleet: {error}", file=sys.stderr)
        return EXIT_USAGE
    except (Cancelled, KeyboardInterrupt):
        return EXIT_INTERRUPTED


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
