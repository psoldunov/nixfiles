import argparse
import contextlib
import datetime
import io
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import support
import agent
import report
from report import Entry, Problem, Run
from inventory import UsageError

import importlib.util

# fleet's entry point is __main__.py, which `import __main__` can't reach.
_spec = importlib.util.spec_from_file_location("fleet_main", Path(support.__file__).resolve().parent.parent / "fleet" / "__main__.py")
cli = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(cli)


def problem_run(directory="/runs/20261109-140000-update"):
    return Run(
        action="update",
        hosts=("Whopper", "BigTasty", "BigMac"),
        local_host="Whopper",
        flake_dir="/home/p/.nixfiles",
        directory=directory,
        started="2026-11-09T14:00:00",
        revision="abc1234",
        entries=(
            Entry("Whopper", "update", warnings=("foo is deprecated",)),
            Entry(
                "BigTasty", "update", "failed", route="nixos-rebuild --target-host psoldunov@bigtasty", exit_code=1,
                log="/runs/x/BigTasty.update.log", errors=(Problem("attribute 'bar' missing", "error: attribute 'bar' missing"),),
                warnings=("foo is deprecated",),
            ),
            Entry("BigMac", "reboot", "failed", note="did not come back within 10 min"),
        ),
    )


class Prompt(unittest.TestCase):
    def test_names_hosts_errors_warnings_and_the_report(self):
        text = agent.prompt(problem_run())
        self.assertIn("`fleet update` ran from Whopper", text)
        self.assertIn("- BigTasty: update failed, exit code 1, nixos-rebuild --target-host psoldunov@bigtasty.", text)
        self.assertIn("  attribute 'bar' missing", text)
        self.assertIn("  Log: /runs/x/BigTasty.update.log", text)
        self.assertIn("- BigMac: reboot failed.\n  did not come back within 10 min", text)
        self.assertIn("- Whopper, BigTasty: foo is deprecated", text)
        self.assertIn("/runs/20261109-140000-update/report.md", text)
        self.assertIn("which `fleet update <hosts>` to run", text)

    def test_installed_and_unknown(self):
        self.assertEqual(agent.installed(lambda name: "/bin/x" if name != "codex" else None), ["claude", "pi"])
        with self.assertRaises(ValueError):
            agent.hand_off("emacs", problem_run())

    def test_hand_off_execs_in_the_flake(self):
        with mock.patch.object(agent.os.path, "isdir", return_value=True), \
                mock.patch.object(agent.os, "chdir") as chdir, mock.patch.object(agent.os, "execvp") as execvp:
            agent.hand_off("pi", problem_run())
        chdir.assert_called_once_with("/home/p/.nixfiles")
        name, argv = execvp.call_args.args
        self.assertEqual((name, argv[0]), ("pi", "pi"))
        self.assertIn("attribute 'bar' missing", argv[1])


class Commands(unittest.TestCase):
    def setUp(self):
        self.cfg = support.config()

    def test_parser(self):
        args = cli.parser().parse_args(["clean", "bigtasty", "shackstack", "--reboot", "--wake"])
        self.assertEqual((args.command, args.hosts, args.reboot, args.wake), ("clean", ["bigtasty", "shackstack"], True, True))
        self.assertEqual(cli.parser().parse_args(["fix", "--agent", "codex"]).agent, "codex")

    def test_capable(self):
        hosts = list(self.cfg.hosts)
        self.assertEqual([h.name for h in cli.capable(self.cfg, "wake", hosts, True)], ["ShackStack"])
        self.assertEqual(len(cli.capable(self.cfg, "sleep", hosts, True)), 4)
        with self.assertRaisesRegex(UsageError, "can't sleep BigTasty"):
            cli.capable(self.cfg, "sleep", [self.cfg.host("BigTasty")], False)
        with self.assertRaisesRegex(UsageError, "can't wake Whopper"):
            cli.capable(self.cfg, "wake", [self.cfg.host("Whopper")], False)

    def test_no_hosts_without_a_terminal(self):
        args = argparse.Namespace(hosts=[], reboot=False, wake=False)
        with self.assertRaisesRegex(UsageError, "name the hosts to rebuild"):
            cli.run_action(self.cfg, "rebuild", args, support.console(), tty=False)

    def test_main_reports_usage_errors(self):
        raw = json.dumps(support.raw_config())
        err = io.StringIO()
        with contextlib.redirect_stderr(err):
            self.assertEqual(cli.main([raw, "sleep", "BigTasty"]), cli.EXIT_USAGE)
            self.assertEqual(cli.main([]), cli.EXIT_USAGE)
        self.assertIn("fleet: can't sleep BigTasty", err.getvalue())

    def test_report_and_fix_without_runs(self):
        with tempfile.TemporaryDirectory() as tmp:
            cfg = support.config(state=tmp)
            with self.assertRaisesRegex(UsageError, "no runs yet"):
                cli.show_report(cfg, None)
            directory = report.new_run_dir(cfg.state_dir, "clean", datetime.datetime(2026, 11, 9))
            report.write(Run("clean", ("Whopper",), "Whopper", "/f", str(directory), "2026-11-09T00:00:00", entries=(Entry("Whopper", "clean"),)))
            out = support.console()
            self.assertEqual(cli.fix(cfg, None, "claude", False, out), 0)
            self.assertIn("had no failures or evaluation warnings", out.text())

    def test_summary(self):
        with tempfile.TemporaryDirectory() as tmp:
            run = problem_run(tmp)
            result = cli.Result(run, report.write(run))
            out = support.console()
            cli.print_summary(result, out)
            text = out.text()
        self.assertIn("fleet update: 2 hosts failed", text)
        self.assertIn("FAILED   BigTasty", text)
        self.assertIn("attribute 'bar' missing; 1 evaluation warning", text)
        self.assertIn("Report: ", text)


if __name__ == "__main__":
    unittest.main()
