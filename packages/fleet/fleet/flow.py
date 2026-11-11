"""One action across the chosen hosts, start to finish: who answers, waking
the ones asked to wake, the flake checkout, the hosts themselves, reboots,
the commit and the report."""

from __future__ import annotations

import datetime
import subprocess
import threading
import sys
from dataclasses import dataclass, replace
from functools import partial
from pathlib import Path
from typing import Callable

import actions
import inventory
import report
from inventory import Config, Host
from report import FLAKE, Entry, Run
from runner import Console, Jobs, Sink, Step, run_parallel, run_steps, wait_for

SWITCHING = ("rebuild", "update")
WAKE_TIMEOUT = 180
SLEEP_TIMEOUT = 60
DOWN_TIMEOUT = 120
UP_TIMEOUT = 600

StepsFor = Callable[[Host, bool], list[Step]]


@dataclass(frozen=True)
class Plan:
    action: str
    hosts: tuple[Host, ...]
    from_all: bool = False
    reboot: bool = False
    wake: bool = False


@dataclass(frozen=True)
class Result:
    run: Run
    report_path: Path
    # Rebooting or suspending this machine waits for the caller, after the
    # report is written and any hand-off to an agent has been offered.
    local_power: tuple[str, Host] | None = None


def _git(cwd: str, *args: str) -> subprocess.CompletedProcess:
    return subprocess.run(["git", *args], cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)


def _revision(cwd: str) -> str:
    head = _git(cwd, "rev-parse", "--short", "HEAD").stdout.strip()
    dirty = bool(_git(cwd, "status", "--porcelain").stdout.strip())
    return f"{head} with uncommitted changes" if head and dirty else head


def _rebasing(cwd: str) -> bool:
    paths = (_git(cwd, "rev-parse", "--git-path", p).stdout.strip() for p in ("rebase-merge", "rebase-apply"))
    return any(p and Path(cwd, p).is_dir() for p in paths)


class Execution:
    def __init__(self, cfg: Config, plan: Plan, console: Console, probe: Callable[[str], bool] = inventory.reachable):
        self.cfg, self.plan, self.console, self.probe = cfg, plan, console, probe
        self.jobs = Jobs()
        self.started = datetime.datetime.now()
        self.dir = report.new_run_dir(cfg.state_dir, plan.action, self.started)
        self.revision = ""
        self.local_power: tuple[str, Host] | None = None
        self._entries: list[Entry] = []
        self._lock = threading.Lock()
        self._finished = threading.Event()

    # The run as a whole.

    def go(self) -> Result:
        interrupted = False
        try:
            self._go()
        except KeyboardInterrupt:
            interrupted = True
            self.jobs.stop_all()
            self.console.line("fleet: interrupted; every host's job was stopped.")
        finally:
            self._finished.set()
        run = Run(
            action=self.plan.action,
            hosts=tuple(h.name for h in self.plan.hosts),
            local_host=self.cfg.local_host,
            flake_dir=self.cfg.flake_dir,
            directory=str(self.dir),
            started=self.started.isoformat(timespec="seconds"),
            revision=self.revision,
            entries=tuple(self._entries),
            interrupted=interrupted,
        )
        return Result(run, report.write(run), None if interrupted else self.local_power)

    def _go(self) -> None:
        action = self.plan.action
        if action == "wake":
            self._wake_action()
            return
        ready = self._ready()
        if not ready:
            self.console.line("fleet: none of the hosts answered, so nothing ran.")
            return
        if not self._keep_sudo(ready):
            return
        if action in SWITCHING and not self._prepare_flake(ready):
            return
        if action == "sleep":
            self._power("sleep", ready, self._confirm_sleep)
            return
        if action == "reboot":
            self._power("reboot", ready, self._confirm_reboot)
            return
        if action == "clean" and self.plan.reboot:
            ready = self._reboot_first(ready)
            if not ready:
                return
        done = self._phase(action, ready, lambda h, tty: actions.BUILDERS[action](self.cfg, h, tty), cwd=self.cfg.flake_dir)
        if action in SWITCHING:
            # Hosts that never answered count too; ones skipped as asleep don't.
            failed = sorted({e.host for e in self._entries if e.failed and e.host != FLAKE})
            if failed:
                self.console.line(f"fleet: not committing, since {', '.join(failed)} failed.")
            else:
                self._commit()
        if self.plan.reboot and action != "clean":
            self._power("reboot", [h for h in ready if any(e.host == h.name and e.status == "ok" for e in done)], self._confirm_reboot)

    def _add(self, entry: Entry) -> Entry:
        with self._lock:
            self._entries.append(entry)
        return entry

    # Running jobs.

    def _job(self, name: str, phase: str, steps: list[Step], solo: bool, cwd: str | None, route: str) -> Entry:
        log = self.dir / f"{name}.{phase.replace(' ', '-')}.log"
        label = None if solo else self.console.label(name)
        with log.open("w") as handle:
            sink = Sink(handle, self.console, label)
            outcome = run_steps(steps, sink, jobs=self.jobs, cwd=cwd, solo=solo)
            sink.close()
        status = "ok" if outcome.ok else ("interrupted" if self.jobs.stopping.is_set() else "failed")
        entry = Entry(
            host=name,
            phase=phase,
            status=status,
            route=route,
            exit_code=outcome.exit_code,
            seconds=outcome.seconds,
            commands=outcome.commands,
            log=str(log),
        )
        return report.analyse(entry, log.read_text(errors="replace"))

    def _route(self, action: str, host: Host) -> str:
        if action in SWITCHING:
            return actions.route(self.cfg, host)
        return "on this machine" if self.cfg.is_local(host) else f"over ssh as {self.cfg.target(host)}"

    def _phase(self, phase: str, hosts: list[Host], steps_for: StepsFor, cwd: str | None = None, follow=None) -> list[Entry]:
        """Run every host's steps, at once except the `last` hosts, which go one
        at a time after the others whether or not those succeeded. One host
        alone gets the terminal. `follow(host, entry)` runs after a host's
        steps succeeded and returns the entry to keep."""
        solo = len(hosts) == 1
        tty = solo and sys.stdin.isatty()
        results: dict[str, Entry] = {}
        for host in hosts:
            self.console.label(host.name)

        def task(host: Host) -> None:
            try:
                entry = self._job(host.name, phase, steps_for(host, tty), solo, cwd, self._route(phase, host))
                if follow and entry.status == "ok":
                    entry = follow(host, entry)
            # Threads never see Ctrl-C; anything else escaping must fail the
            # host, or it drops out of the run and the commit goes ahead.
            except BaseException as error:
                entry = Entry(host.name, phase, "failed", note=f"fleet hit an error running this host: {error!r}")
            results[host.name] = self._add(entry)
            self.console.line(f"===== {host.name}: {phase} {entry.status} =====")

        first = [h for h in hosts if not h.last]
        if first:
            names = ", ".join(h.name for h in first)
            self.console.line(f"===== {phase} {names}" + (f" at once (logs in {self.dir})" if len(first) > 1 else "") + " =====")
            run_parallel([partial(task, h) for h in first], self.jobs)
        for host in (h for h in hosts if h.last):
            self.console.line(f"===== {phase} {host.name} now that the others are done =====")
            run_parallel([partial(task, host)], self.jobs)
        return [results[h.name] for h in hosts if h.name in results]

    def _keep_sudo(self, ready: list[Host]) -> bool:
        """Ask for this machine's sudo password once, up front, and keep the
        ticket fresh, so the jobs that run sudo here later reuse it."""
        action = self.plan.action
        local = any(self.cfg.is_local(h) for h in ready)
        if not (action == "update" or (local and action in ("rebuild", "clean"))):
            return True
        if subprocess.run(["sudo", "-v"]).returncode != 0:
            self._add(Entry(self.cfg.local_host, "sudo", "failed", note="sudo -v failed, so nothing ran"))
            return False

        def refresh() -> None:
            while not self._finished.wait(50):
                subprocess.run(["sudo", "-n", "true"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        threading.Thread(target=refresh, daemon=True).start()
        return True

    # Who answers, and waking the ones asked to wake.

    def _ready(self) -> list[Host]:
        hosts, action = list(self.plan.hosts), self.plan.action
        online = inventory.probe(self.cfg, hosts, self.probe)
        ready, sleepers = [], []
        for host in hosts:
            if online[host.name]:
                ready.append(host)
            elif action == "sleep":
                self._add(Entry(host.name, action, "skipped", note="already asleep or away (no answer over ssh)"))
            elif self.plan.wake and host.wake_mac:
                sleepers.append(host)
            elif self.plan.from_all and host.roaming:
                self.console.line(f"fleet: {host.name} is not answering; skipping it.")
                self._add(Entry(host.name, action, "skipped", note="asleep or away (no answer over ssh)"))
            else:
                note = f"not answering over ssh ({self.cfg.target(host)}, 5 s, no prompts)"
                self._add(Entry(host.name, action, "failed", note=note))
        woken = {h.name for h in self._wake(sleepers)}
        return [h for h in hosts if h in ready or h.name in woken]

    def _wake(self, hosts: list[Host]) -> list[Host]:
        if not hosts:
            return []
        woken: list[Host] = []

        def task(host: Host) -> None:
            try:
                entry = self._add(self._wake_one(host))
            except BaseException as error:  # as in _phase: fail the host, don't drop it
                entry = self._add(Entry(host.name, "wake", "failed", note=f"fleet hit an error waking this host: {error!r}"))
            if entry.status == "ok":
                woken.append(host)

        for host in hosts:
            self.console.label(host.name)
        self.console.line(f"===== waking {', '.join(h.name for h in hosts)} =====")
        run_parallel([partial(task, h) for h in hosts], self.jobs)
        return woken

    def _wake_one(self, host: Host) -> Entry:
        label = self.console.label(host.name)
        try:
            inventory.send_wake(host.wake_mac, self.cfg.wol_broadcast)
        except OSError as error:
            return Entry(host.name, "wake", "failed", note=f"could not send the Wake-on-LAN packet: {error}")
        self.console.line(f"{label}sent Wake-on-LAN to {host.wake_mac}; waiting up to {WAKE_TIMEOUT // 60} min for ssh")
        took = wait_for(self.cfg.target(host), True, WAKE_TIMEOUT, self.jobs, self.probe)
        if took is None:
            note = f"sent Wake-on-LAN to {host.wake_mac}, but it did not answer over ssh within {WAKE_TIMEOUT // 60} min"
            return Entry(host.name, "wake", "failed", note=note, route=f"Wake-on-LAN to {self.cfg.wol_broadcast}")
        return Entry(host.name, "wake", "ok", note=f"awake after {took:.0f} s", seconds=took)

    def _wake_action(self) -> None:
        online = inventory.probe(self.cfg, list(self.plan.hosts), self.probe)
        for host in self.plan.hosts:
            if online[host.name]:
                self._add(Entry(host.name, "wake", "ok", note="already awake"))
        self._wake([h for h in self.plan.hosts if not online[h.name]])

    # Reboot and sleep.

    def _power(self, action: str, hosts: list[Host], confirm) -> None:
        """Reboot or suspend the remote hosts and watch them go down (and come
        back); this machine is left for the caller to do last."""
        remote = [h for h in hosts if not self.cfg.is_local(h)]
        if remote:
            self._phase(action, remote, lambda h, tty: actions.BUILDERS[action](self.cfg, h, tty), follow=confirm)
        local = next((h for h in hosts if self.cfg.is_local(h)), None)
        if local:
            note = "left for last: fleet runs it after writing this report, so the report can't show whether it happened"
            self._add(Entry(local.name, action, "deferred", note=note, route="on this machine"))
            self.local_power = (action, local)

    def _reboot_first(self, hosts: list[Host]) -> list[Host]:
        """Before a clean: reboot the remote hosts so nothing still running
        holds old store paths, and keep the ones that came back. This machine
        can't reboot without ending fleet, so it is cleaned without one."""
        remote = [h for h in hosts if not self.cfg.is_local(h)]
        back: set[str] = set()
        if remote:
            done = self._phase("reboot", remote, lambda h, tty: actions.BUILDERS["reboot"](self.cfg, h, tty), follow=self._confirm_reboot)
            back = {e.host for e in done if e.status == "ok"}
        for host in hosts:
            if self.cfg.is_local(host):
                note = "not rebooted first: fleet can't keep running across this machine's reboot"
                self.console.line(f"fleet: {host.name} is this machine, so it is cleaned without rebooting first.")
                self._add(Entry(host.name, "reboot", "skipped", note=note))
                back.add(host.name)
        return [h for h in hosts if h.name in back]

    def _confirm_sleep(self, host: Host, entry: Entry) -> Entry:
        gone = wait_for(self.cfg.target(host), False, SLEEP_TIMEOUT, self.jobs, self.probe, interval=3)
        if gone is None:
            return replace(entry, status="failed", note=f"still answering over ssh {SLEEP_TIMEOUT} s after the sleep command")
        return replace(entry, note=f"asleep after {gone:.0f} s")

    def _confirm_reboot(self, host: Host, entry: Entry) -> Entry:
        target, label = self.cfg.target(host), self.console.label(host.name)
        gone = wait_for(target, False, DOWN_TIMEOUT, self.jobs, self.probe, interval=3)
        if gone is None:
            return replace(entry, status="failed", note=f"still answering over ssh {DOWN_TIMEOUT // 60} min after the reboot command")
        self.console.line(f"{label}went down; waiting up to {UP_TIMEOUT // 60} min for it to come back")
        back = wait_for(target, True, UP_TIMEOUT, self.jobs, self.probe)
        if back is None:
            hint = " (FileVault keeps a Mac at its login screen after a reboot until someone unlocks it)" if host.kind == "darwin" else ""
            return replace(entry, status="failed", note=f"did not come back within {UP_TIMEOUT // 60} min{hint}")
        return replace(entry, note=f"back after {gone + back:.0f} s", seconds=entry.seconds + gone + back)

    # The flake checkout.

    def _flake_job(self, phase: str, steps: list[Step]) -> Entry:
        return self._job(FLAKE, phase, steps, solo=True, cwd=self.cfg.flake_dir, route=f"in {self.cfg.flake_dir}")

    def _prepare_flake(self, ready: list[Host]) -> bool:
        """Start from the other workstations' latest push (--autostash carries
        local edits across), stage everything, and for update bump flake.lock
        and the pins. False when nothing should be switched."""
        cwd = self.cfg.flake_dir
        if not Path(cwd, "flake.nix").is_file():
            self._add(Entry(FLAKE, "checkout", "failed", note=f"no flake.nix in {cwd} (FLAKE_DIR picks another checkout)"))
            return False
        pull = self._flake_job("git pull", [Step(("git", "pull", "--rebase", "--autostash", "--quiet"))])
        if pull.status != "ok":
            if pull.status == "interrupted" or _rebasing(cwd):
                note = "" if pull.status == "interrupted" else "git pull stopped on a conflict; resolve it (or git rebase --abort) and rerun"
                self._add(replace(pull, note=note))
                return False
            self.console.line("fleet: git pull failed; building the local tree as it is.")
            pull = replace(pull, status="ok", errors=(), note="git pull failed; built the local tree as it is")
        # An autostash that doesn't apply cleanly still exits 0, leaving conflicts
        # that `git add -A` would stage, markers and all, for the commit.
        unmerged = _git(cwd, "diff", "--name-only", "--diff-filter=U")
        if unmerged.returncode != 0 or unmerged.stdout.strip():
            files = ", ".join(unmerged.stdout.splitlines()) or "the checkout (git diff failed)"
            note = f"unresolved conflicts in {files}; resolve them and rerun (an autostash that didn't apply stays in git stash list)"
            self._add(replace(pull, status="failed", note=note))
            return False
        self._add(pull)
        if _git(cwd, "add", "-A").returncode != 0:
            self._add(Entry(FLAKE, "git add", "failed", note=f"git add -A failed in {cwd}, so nothing was switched"))
            return False
        self.revision = _revision(cwd)
        if self.plan.action == "update":
            bumped = self._add(self._flake_job("flake update", actions.flake_update(self.cfg)))
            if bumped.status != "ok":
                for host in ready:
                    self._add(Entry(host.name, "update", "skipped", note="not run: updating the flake failed"))
                return False
        return True

    def _commit(self) -> None:
        """Commit everything (if anything changed) and push, as the old scripts did."""
        cwd = self.cfg.flake_dir
        changed = _git(cwd, "diff", "--cached", "--quiet").returncode != 0 or _git(cwd, "diff", "--quiet").returncode != 0
        message = f"{self.plan.action} commit {datetime.datetime.now():%d/%m/%Y %H:%M:%S}"
        steps = [Step(("git", "commit", "-am", message))] if changed else []
        if not changed:
            self.console.line(f"fleet {self.plan.action} succeeded; nothing to commit.")
        entry = self._flake_job("commit and push", [*steps, Step(("git", "push"))])
        if entry.status == "failed" and entry.commands[-1] == "git push":
            entry = replace(entry, note="git push failed; the commit is local only")
        self._add(entry)
