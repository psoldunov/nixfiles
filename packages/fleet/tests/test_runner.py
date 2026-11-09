import io
import unittest

import support
from runner import Jobs, Sink, Step, run_steps, wait_for


def run(steps, solo=False):
    console = support.console()
    log = io.StringIO()
    sink = Sink(log, console, None if solo else console.label("BigTasty"))
    outcome = run_steps(steps, sink, jobs=Jobs(), solo=solo)
    sink.close()
    return outcome, log.getvalue(), console.text()


def sh(script, **kwargs):
    return Step(("sh", "-c", script), **kwargs)


class RunSteps(unittest.TestCase):
    def test_output_is_logged_and_labelled(self):
        outcome, log, shown = run([sh("echo hello; echo 'evaluation warning: x' >&2; exit 3")])
        self.assertFalse(outcome.ok)
        self.assertEqual(outcome.exit_code, 3)
        self.assertIn("hello\nevaluation warning: x\n", log)
        self.assertIn("[BigTasty]   hello", shown)

    def test_stops_at_the_first_failure(self):
        outcome, log, _ = run([sh("exit 1"), sh("echo second")])
        self.assertEqual(len(outcome.commands), 1)
        self.assertNotIn("second", log)

    def test_flake_archive_path_reaches_later_steps(self):
        archive = sh('echo progress >&2; echo \'{"path": "/nix/store/abc-source"}\'', captures_src=True)
        outcome, log, _ = run([archive, sh("echo got {src}")])
        self.assertTrue(outcome.ok)
        self.assertIn("progress\n", log)
        self.assertIn("got /nix/store/abc-source\n", log)
        self.assertNotIn('\n{"path"', log)  # stdout went to fleet, not the log

    def test_bad_archive_output_fails(self):
        outcome, log, _ = run([sh("echo nope", captures_src=True), sh("echo never")])
        self.assertFalse(outcome.ok)
        self.assertIn("expected JSON with a store path", log)

    def test_missing_program(self):
        outcome, log, _ = run([Step(("fleet-test-no-such-program",))])
        self.assertEqual(outcome.exit_code, 127)
        self.assertIn("could not run fleet-test-no-such-program", log)

    def test_accepted_exit_codes(self):
        outcome, _, _ = run([sh("exit 255", ok_codes=frozenset({0, 255}))])
        self.assertTrue(outcome.ok)

    def test_one_job_passes_raw_output_through_and_logs_it_clean(self):
        outcome, log, shown = run([sh(r"printf '\033[31mred\033[0m\n50%%\r100%%\n'")], solo=True)
        self.assertTrue(outcome.ok)
        self.assertIn("\x1b[31mred", shown)
        self.assertIn("red\n100%\n", log)

    def test_env(self):
        _, log, _ = run([sh('echo "dir=$FLAKE_DIR"', env=(("FLAKE_DIR", "/flake"),))])
        self.assertIn("dir=/flake", log)


class WaitFor(unittest.TestCase):
    def test_counts_until_the_probe_says_so(self):
        answers = iter([True, True, False])
        took = wait_for("h", False, 10, Jobs(), lambda _: next(answers), interval=0)
        self.assertIsNotNone(took)

    def test_gives_up(self):
        self.assertIsNone(wait_for("h", True, 0, Jobs(), lambda _: False, interval=0))

    def test_stops_with_the_run(self):
        jobs = Jobs()
        jobs.stop_all()
        self.assertIsNone(wait_for("h", True, 10, jobs, lambda _: False, interval=0))


if __name__ == "__main__":
    unittest.main()
