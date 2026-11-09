import datetime
import tempfile
import unittest
from pathlib import Path

import support  # noqa: F401  (puts fleet on sys.path)
import report
from report import Entry, Run

SHOW_TRACE = """\
building the system configuration...
error:
       … while calling the 'head' builtin
         at /nix/store/abc-source/lib/attrsets.nix:1575:11:

       … while evaluating the option `system.build.toplevel':

       error: The option `services.foo.enable' does not exist. Definition values:
       - In `/nix/store/abc-source/hosts/bigtasty/modules/foo.nix': true
Command 'nix --extra-experimental-features 'nix-command flakes' build' returned non-zero exit status 1."""

BUILD_FAILURE = """\
error: builder for '/nix/store/xyz-concierge-1.0.drv' failed with exit code 101;
       last 2 log lines:
       > error[E0425]: cannot find value `x` in this scope
       > error: could not compile `concierge`
       For full logs, run 'nix log /nix/store/xyz-concierge-1.0.drv'.
error: 1 dependencies of derivation '/nix/store/sys-nixos-system.drv' failed to build
error: 1 dependencies of derivation '/nix/store/sys-nixos-system.drv' failed to build"""

WARNINGS = """\
evaluation warning: The option `programs.foo' has been renamed to `programs.bar'.
trace: warning: xorg.libX11 is deprecated
  and will be removed
warning: Git tree '/home/p/.nixfiles' is dirty
evaluation warning: The option `programs.foo' has been renamed to `programs.bar'.
"""


class CleanLine(unittest.TestCase):
    def test_strips_colour_codes(self):
        self.assertEqual(report.clean_line("\x1b[31;1merror:\x1b[0m boom"), "error: boom")

    def test_keeps_what_the_last_carriage_return_left(self):
        line = "[1/3 built] copying\r\x1b[Kevaluation warning: x\r"
        self.assertEqual(report.clean_line(line), "evaluation warning: x")

    def test_blank(self):
        self.assertEqual(report.clean_line("\r\x1b[K"), "")


class Warnings(unittest.TestCase):
    def test_evaluation_and_trace_warnings_deduplicated(self):
        found = report.find_warnings(WARNINGS.splitlines())
        self.assertEqual(
            found,
            [
                "The option `programs.foo' has been renamed to `programs.bar'.",
                "xorg.libX11 is deprecated\nand will be removed",
            ],
        )

    def test_dirty_tree_is_not_an_evaluation_warning(self):
        self.assertEqual(report.find_warnings(["warning: Git tree '/x' is dirty"]), [])


class Errors(unittest.TestCase):
    def test_show_trace_headline_is_the_innermost_error(self):
        found = report.find_errors(SHOW_TRACE.splitlines())
        self.assertEqual(found[0].headline, "The option `services.foo.enable' does not exist. Definition values:")
        self.assertIn("… while calling the 'head' builtin", found[0].detail)
        self.assertIn("returned non-zero exit status 1", found[1].headline)

    def test_builder_failure_and_its_consequence_once_each(self):
        found = report.find_errors(BUILD_FAILURE.splitlines())
        self.assertEqual(len(found), 2)
        self.assertTrue(found[0].headline.startswith("builder for '/nix/store/xyz-concierge-1.0.drv' failed"))
        self.assertIn("could not compile", found[0].detail)
        self.assertTrue(found[1].headline.startswith("1 dependencies of derivation"))

    def test_tool_failures(self):
        lines = ["ssh: connect to host bigmac.local port 22: Connection refused", "fatal: unable to access 'x'"]
        self.assertEqual([p.headline for p in report.find_errors(lines)], lines)

    def test_long_blocks_are_capped(self):
        block = ["error:"] + [f"       line {i}" for i in range(500)]
        detail = report.find_errors(block)[0].detail
        self.assertLess(len(detail.splitlines()), report.MAX_BLOCK_LINES + 2)
        self.assertIn("lines left out", detail)


class Analyse(unittest.TestCase):
    def test_failed_entry_gets_errors_and_warnings(self):
        entry = report.analyse(Entry("BigTasty", "rebuild", "failed", exit_code=1), WARNINGS + SHOW_TRACE)
        self.assertEqual(len(entry.warnings), 2)
        self.assertTrue(entry.errors[0].headline.startswith("The option `services.foo.enable'"))

    def test_successful_entry_keeps_only_warnings(self):
        entry = report.analyse(Entry("Whopper", "rebuild"), WARNINGS + "error: not a failure\n")
        self.assertEqual(entry.errors, ())
        self.assertEqual(len(entry.warnings), 2)

    def test_failure_without_a_recognisable_line(self):
        entry = report.analyse(Entry("BigMac", "clean", "failed", exit_code=3), "something odd\n")
        self.assertEqual(entry.errors[0].headline, "exited with code 3")
        self.assertIn("something odd", entry.errors[0].detail)


def sample_run(directory, entries):
    return Run(
        action="rebuild",
        hosts=("Whopper", "BigTasty"),
        local_host="Whopper",
        flake_dir="/home/p/.nixfiles",
        directory=str(directory),
        started="2026-11-09T14:00:00",
        revision="abc1234",
        entries=tuple(entries),
    )


class Files(unittest.TestCase):
    def test_markdown_and_json_round_trip(self):
        with tempfile.TemporaryDirectory() as tmp:
            log = Path(tmp, "BigTasty.rebuild.log")
            log.write_text(SHOW_TRACE + "\n")
            failed = report.analyse(
                Entry("BigTasty", "rebuild", "failed", route="nixos-rebuild", exit_code=1, log=str(log), commands=("nixos-rebuild switch",)),
                log.read_text(),
            )
            ok = Entry("Whopper", "rebuild", warnings=("renamed option",))
            run = sample_run(tmp, [ok, failed])
            path = report.write(run)
            text = path.read_text()
            self.assertIn("# fleet rebuild: 1 host failed", text)
            self.assertIn("## BigTasty: rebuild failed", text)
            self.assertIn(f"- Full log: {log}", text)
            self.assertIn("Last 60 lines of the log", text)
            self.assertIn("## Evaluation warnings", text)
            self.assertIn("- Whopper:", text)
            self.assertEqual(report.load(Path(tmp)), run)

    def test_verdicts(self):
        self.assertEqual(report.verdict(sample_run("/x", [Entry("Whopper", "rebuild")])), "succeeded")
        flake_only = sample_run("/x", [Entry(report.FLAKE, "flake update", "failed")])
        self.assertEqual(report.verdict(flake_only), "the flake checkout step failed")

    def test_run_dirs_are_pruned_and_unique(self):
        with tempfile.TemporaryDirectory() as tmp:
            now = datetime.datetime(2026, 11, 9, 14, 0, 0)
            for i in range(report.KEEP_RUNS + 5):
                report.new_run_dir(tmp, "clean", now + datetime.timedelta(minutes=i))
            again = report.new_run_dir(tmp, "clean", now + datetime.timedelta(minutes=report.KEEP_RUNS + 4))
            runs = sorted(report.runs_dir(tmp).iterdir())
            self.assertEqual(len(runs), report.KEEP_RUNS)
            self.assertTrue(again.name.endswith("-clean-2"))

    def test_find_run_takes_the_newest_with_a_report(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = report.runs_dir(tmp)
            for name in ("20261101-000000-rebuild", "20261102-000000-update", "20261103-000000-clean"):
                (root / name).mkdir(parents=True)
            (root / "20261101-000000-rebuild" / "report.json").write_text("{}")
            (root / "20261102-000000-update" / "report.json").write_text("{}")
            self.assertEqual(report.find_run(tmp, None).name, "20261102-000000-update")
            self.assertIsNone(report.find_run(tmp, "20261103-000000-clean"))


if __name__ == "__main__":
    unittest.main()
