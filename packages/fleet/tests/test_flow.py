import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import support
import actions
import flow
from flow import Execution, Plan
from runner import Step

FAKE_SWITCH = {
    "BigTasty": "echo 'evaluation warning: foo is deprecated'; echo switched",
    "BigKing": "echo \"error: attribute 'bar' missing\" >&2; exit 1",
    "PiHome": "echo 'evaluation warning: foo is deprecated'",
}
GIT_ENV = {
    "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t", "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@t",
    "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_CONFIG_NOSYSTEM": "1",
}


# Programs that reach or change a real machine. Every flow test gets stand-ins
# for them on PATH that refuse, so a step that slips past the fake builders
# can never touch a host; tearDown fails the test if one was called.
GUARDED = ("ssh", "sudo", "nixos-rebuild", "darwin-rebuild", "systemctl", "shutdown", "pmset", "nix")


def fake_builder(cfg, host, tty):
    return [Step(("sh", "-c", FAKE_SWITCH.get(host.name, "true")))]


class FlowCase(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.flake = Path(self.tmp.name, "flake")
        self.flake.mkdir()
        (self.flake / "flake.nix").write_text("{}\n")
        env = {**os.environ, **GIT_ENV}
        subprocess.run(["git", "init", "-q"], cwd=self.flake, check=True, env=env)
        subprocess.run(["git", "add", "-A"], cwd=self.flake, check=True, env=env)
        subprocess.run(["git", "commit", "-qm", "init"], cwd=self.flake, check=True, env=env)
        self.cfg = support.config("Whopper", state=str(Path(self.tmp.name, "state")), flake=str(self.flake))
        self.console = support.console()
        self.guard_log = Path(self.tmp.name, "guarded-calls")
        guard_bin = Path(self.tmp.name, "bin")
        guard_bin.mkdir()
        for name in GUARDED:
            stand_in = guard_bin / name
            stand_in.write_text(f'#!/bin/sh\necho "{name} $*" >> "{self.guard_log}"\nexit 97\n')
            stand_in.chmod(0o755)
        patches = [
            mock.patch.dict(os.environ, {**GIT_ENV, "PATH": f"{guard_bin}:{os.environ['PATH']}"}),
            mock.patch.dict(actions.BUILDERS, {name: fake_builder for name in actions.BUILDERS}),
        ]
        for patch in patches:
            patch.start()
            self.addCleanup(patch.stop)

    def tearDown(self):
        called = self.guard_log.read_text() if self.guard_log.exists() else ""
        self.tmp.cleanup()
        self.assertEqual(called, "", "a flow test ran a program that reaches real hosts")

    def plan(self, action, names, **kwargs):
        return Plan(action, tuple(self.cfg.host(n) for n in names), **kwargs)

    def go(self, plan, online=lambda target: True):
        return Execution(self.cfg, plan, self.console, probe=online).go()


class Rebuild(FlowCase):
    def test_failures_and_warnings_are_collected_and_nothing_is_committed(self):
        result = self.go(self.plan("rebuild", ["BigTasty", "BigKing", "PiHome"]))
        run = result.run
        by_host = {(e.host, e.phase): e for e in run.entries}
        self.assertEqual(by_host[("BigKing", "rebuild")].status, "failed")
        self.assertEqual(by_host[("BigKing", "rebuild")].errors[0].headline, "attribute 'bar' missing")
        self.assertEqual(by_host[("BigTasty", "rebuild")].status, "ok")
        self.assertEqual(run.warnings(), {"foo is deprecated": ["BigTasty", "PiHome"]})
        self.assertNotIn(("flake", "commit and push"), by_host)
        self.assertEqual(by_host[("flake", "git pull")].note, "git pull failed; built the local tree as it is")
        self.assertIn("not committing, since BigKing failed", self.console.text())
        self.assertIn("PiHome now that the others are done", self.console.text())
        self.assertTrue(result.report_path.is_file())
        self.assertIn("attribute 'bar' missing", result.report_path.read_text())

    def test_success_commits_and_reports_a_failed_push(self):
        (self.flake / "new.nix").write_text("{}\n")
        result = self.go(self.plan("rebuild", ["BigTasty"]))
        commit = [e for e in result.run.entries if e.phase == "commit and push"][0]
        self.assertEqual(commit.status, "failed")
        self.assertEqual(commit.note, "git push failed; the commit is local only")
        log = subprocess.run(["git", "log", "--format=%s", "-1"], cwd=self.flake, stdout=subprocess.PIPE, text=True).stdout
        self.assertTrue(log.startswith("rebuild commit "))

    def test_unanswering_hosts(self):
        hosts = [h.name for h in self.cfg.hosts if h.name != "Whopper"]
        plan = self.plan("clean", hosts, from_all=True)
        run = self.go(plan, online=lambda target: target.endswith(("bigtasty", "pihome"))).run
        status = {e.host: (e.status, e.note) for e in run.entries}
        self.assertEqual(status["ShackStack"][0], "skipped")
        self.assertEqual(status["BigKing"][0], "failed")
        self.assertIn("not answering over ssh", status["BigKing"][1])
        self.assertEqual(status["BigTasty"], ("ok", ""))

    def test_a_host_that_never_answered_holds_the_commit_back(self):
        run = self.go(self.plan("rebuild", ["BigTasty", "BigKing"]), online=lambda t: t.endswith("bigtasty")).run
        self.assertNotIn("commit and push", [e.phase for e in run.entries])
        self.assertIn("not committing, since BigKing failed", self.console.text())

    def test_missing_checkout(self):
        self.cfg = support.config("Whopper", state=self.cfg.state_dir, flake=str(Path(self.tmp.name, "nowhere")))
        run = self.go(self.plan("rebuild", ["BigTasty"])).run
        self.assertEqual([(e.host, e.status) for e in run.entries], [("flake", "failed")])


class Power(FlowCase):
    def test_reboot_waits_for_down_and_up_and_leaves_this_machine_last(self):
        waits = []

        def fake_wait(target, up, timeout, jobs, probe, interval=5):
            waits.append((target, up))
            return 7.0

        with mock.patch.object(flow, "wait_for", fake_wait):
            result = self.go(self.plan("reboot", ["Whopper", "BigTasty"]))
        (entry,) = result.run.entries
        self.assertEqual((entry.host, entry.status, entry.note), ("BigTasty", "ok", "back after 14 s"))
        self.assertEqual(waits, [("psoldunov@bigtasty", False), ("psoldunov@bigtasty", True)])
        self.assertEqual(result.local_power, ("reboot", self.cfg.host("Whopper")))

    def test_mac_that_stays_down_gets_the_filevault_hint(self):
        answers = iter([7.0, None])
        with mock.patch.object(flow, "wait_for", lambda *a, **k: next(answers)):
            (entry,) = self.go(self.plan("reboot", ["BigMac"])).run.entries
        self.assertEqual(entry.status, "failed")
        self.assertIn("FileVault", entry.note)

    def test_rebuild_then_reboot_only_what_succeeded(self):
        with mock.patch.object(flow, "wait_for", lambda *a, **k: 1.0):
            run = self.go(self.plan("rebuild", ["BigTasty", "BigKing"], reboot=True)).run
        rebooted = [e.host for e in run.entries if e.phase == "reboot"]
        self.assertEqual(rebooted, ["BigTasty"])  # BigKing's rebuild failed, so it stays up
        with mock.patch.object(flow, "wait_for", lambda *a, **k: 1.0):
            run = self.go(self.plan("rebuild", ["BigTasty", "PiHome"], reboot=True)).run
        rebooted = [e.host for e in run.entries if e.phase == "reboot"]
        self.assertEqual(rebooted, ["BigTasty", "PiHome"])

    def test_the_guard_catches_a_real_host_command(self):
        with mock.patch.dict(actions.BUILDERS, {"reboot": actions.reboot}), \
                mock.patch.object(flow, "wait_for", lambda *a, **k: 1.0):
            (entry,) = self.go(self.plan("reboot", ["BigTasty"])).run.entries
        self.assertEqual((entry.status, entry.exit_code), ("failed", 97))
        self.assertIn("ssh -T", self.guard_log.read_text())
        self.guard_log.unlink()

    def test_clean_reboots_first_and_cleans_only_hosts_that_came_back(self):
        answers = {"psoldunov@bigtasty": [7.0, 9.0], "psoldunov@bigking": [7.0, None]}
        with mock.patch.object(flow, "wait_for", lambda target, *a, **k: answers[target].pop(0)), \
                mock.patch.object(flow.Execution, "_keep_sudo", return_value=True):
            result = self.go(self.plan("clean", ["Whopper", "BigTasty", "BigKing"], reboot=True))
        phases = [e.phase for e in result.run.entries]
        self.assertEqual(phases, ["reboot", "reboot", "reboot", "clean", "clean"])  # every reboot before any clean
        steps = {(e.host, e.phase, e.status) for e in result.run.entries}
        self.assertEqual(
            steps,
            {
                ("BigTasty", "reboot", "ok"),
                ("BigKing", "reboot", "failed"),
                ("Whopper", "reboot", "skipped"),
                ("Whopper", "clean", "ok"),
                ("BigTasty", "clean", "ok"),
            },
        )
        self.assertIsNone(result.local_power)
        self.assertIn("cleaned without rebooting first", self.console.text())

    def test_wake(self):
        sent = []
        with mock.patch.object(flow.inventory, "send_wake", lambda mac, bcast: sent.append((mac, bcast))), \
                mock.patch.object(flow, "wait_for", lambda *a, **k: 30.0):
            run = self.go(self.plan("wake", ["ShackStack"]), online=lambda t: False).run
        self.assertEqual(sent, [("cc:28:aa:86:dd:6a", "10.24.24.255")])
        self.assertEqual([(e.status, e.note) for e in run.entries], [("ok", "awake after 30 s")])

    def test_wake_first_then_rebuild(self):
        with mock.patch.object(flow.inventory, "send_wake", lambda mac, bcast: None), \
                mock.patch.object(flow, "wait_for", lambda *a, **k: 20.0):
            run = self.go(self.plan("rebuild", ["ShackStack"], wake=True), online=lambda t: False).run
        phases = [(e.host, e.phase, e.status) for e in run.entries if e.host == "ShackStack"]
        self.assertEqual(phases, [("ShackStack", "wake", "ok"), ("ShackStack", "rebuild", "ok")])

    def test_sleep_skips_hosts_already_asleep(self):
        with mock.patch.object(flow, "wait_for", lambda *a, **k: 2.0):
            result = self.go(self.plan("sleep", ["ShackStack", "BigMac"]), online=lambda t: t.endswith("bigmac"))
        status = {e.host: (e.status, e.note) for e in result.run.entries}
        self.assertEqual(status["ShackStack"][0], "skipped")
        self.assertEqual(status["BigMac"], ("ok", "asleep after 2 s"))


if __name__ == "__main__":
    unittest.main()
