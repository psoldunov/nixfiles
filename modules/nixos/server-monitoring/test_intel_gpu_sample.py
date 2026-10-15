#!/usr/bin/env python3
"""Focused tests for modules/nixos/server-monitoring/intel-gpu-sample.py."""

import fcntl
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent
SAMPLER = ROOT / "intel-gpu-sample.py"


def real_schema_samples(final_busy=12.5, engine_name="Render/3D"):
    """Minimal engine fixture from IGT v2.3's JSON emitter, not a live capture.

    https://gitlab.freedesktop.org/drm/igt-gpu-tools/-/blob/v2.3/tools/intel_gpu_top.c
    json_open_struct/json_add_member emit an array of samples; print_engine
    emits busy/sema/wait and the percent unit beneath each engine display name.
    """
    return [
        {"engines": {engine_name: {"busy": 1.0, "sema": 0.0, "wait": 0.0, "unit": "%"}}},
        {"engines": {engine_name: {"busy": 7.0, "sema": 0.0, "wait": 0.0, "unit": "%"}}},
        {"engines": {engine_name: {"busy": final_busy, "sema": 0.0, "wait": 0.0, "unit": "%"}}},
    ]


class IntelGpuSamplerTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        self.sysfs = self.root / "sys" / "class" / "drm"
        self.sysfs.mkdir(parents=True)
        self.output = self.root / "textfile" / "intel-gpu.prom"
        self.fake_top = self.root / "fake-intel-gpu-top"
        self.fake_top.write_text(
            "#!/usr/bin/env python3\n"
            "import json, os, sys, time\n"
            "log = os.environ.get('FAKE_CALL_LOG')\n"
            "if log:\n"
            "    with open(log, 'a', encoding='utf-8') as handle:\n"
            "        handle.write(json.dumps(sys.argv[1:]) + '\\n')\n"
            "mode = os.environ.get('FAKE_MODE', 'json')\n"
            "if mode == 'sleep':\n"
            "    time.sleep(float(os.environ.get('FAKE_SLEEP', '2')))\n"
            "elif mode == 'error':\n"
            "    print('permission denied', file=sys.stderr)\n"
            "    raise SystemExit(7)\n"
            "else:\n"
            "    print(os.environ.get('FAKE_PAYLOAD', '[]'))\n"
        )
        self.fake_top.chmod(0o755)
        self.environment = os.environ.copy()
        self.environment["FAKE_PAYLOAD"] = json.dumps(real_schema_samples())

    def tearDown(self):
        self.tempdir.cleanup()

    def add_card(self, name, vendor):
        vendor_file = self.sysfs / name / "device" / "vendor"
        vendor_file.parent.mkdir(parents=True)
        vendor_file.write_text(vendor + "\n")

    def run_sampler(self, *, timeout=1.0, environment=None):
        env = self.environment.copy()
        if environment:
            env.update(environment)
        return subprocess.run(
            [
                sys.executable,
                str(SAMPLER),
                "--output", str(self.output),
                "--sysfs-root", str(self.sysfs),
                "--intel-gpu-top", str(self.fake_top),
                "--timeout-seconds", str(timeout),
            ],
            text=True,
            capture_output=True,
            env=env,
            check=False,
        )

    def read_output(self):
        return self.output.read_text(encoding="utf-8")

    def test_real_finite_schema_discards_initial_sample_and_emits_each_engine(self):
        self.add_card("card2", "0x8086")
        payload = real_schema_samples(23.25)
        payload[-1]["engines"]["Video"] = {"busy": 50, "unit": "%"}
        result = self.run_sampler(environment={"FAKE_PAYLOAD": json.dumps(payload)})

        self.assertEqual(result.returncode, 0, result.stderr)
        text = self.read_output()
        self.assertIn('server_intel_gpu_engine_busy_percent{device="card2",engine="Render/3D"} 23.25', text)
        self.assertIn('server_intel_gpu_engine_busy_percent{device="card2",engine="Video"} 50', text)
        self.assertNotIn('} 1.0', text)  # The first intel_gpu_top record is discarded.
        self.assertIn("server_intel_gpu_sample_success 1", text)
        self.assertRegex(text, r"server_intel_gpu_last_success_timestamp_seconds [0-9]+(?:\.[0-9]+)?\n")
        self.assertNotIn("engine_busy_percent_sum", text)

    def test_actual_bigtasty_empty_clients_capture(self):
        # Actual idle BigTasty intel_gpu_top 2.3 capture, including its missing
        # sample commas and original array framing; not synthetic zero values.
        payload = (ROOT / "fixtures" / "intel-gpu-top-2.3-empty-clients.txt").read_text()
        self.add_card("card2", "0x8086")
        result = self.run_sampler(environment={"FAKE_PAYLOAD": payload})

        self.assertEqual(result.returncode, 0, result.stderr)
        text = self.read_output()
        engine_lines = [line for line in text.splitlines()
                        if line.startswith("server_intel_gpu_engine_busy_percent")]
        self.assertEqual(engine_lines, [
            f'server_intel_gpu_engine_busy_percent{{device="card2",engine="{engine}"}} 0'
            for engine in ("Blitter", "Render/3D", "Video", "VideoEnhance")
        ])
        self.assertIn("server_intel_gpu_sample_success 1\n", text)

    def test_empty_clients_allows_only_missing_sample_commas(self):
        self.add_card("card2", "0x8086")
        label = 'object-like }{ and },{ with \\"quote"\nnext'
        samples = real_schema_samples(31.5, label)
        for sample in samples:
            sample["clients"] = {}
        records = [json.dumps(sample) for sample in samples]
        for first, second in ((",", ""), ("", ","), ("", ""), (",", ",")):
            with self.subTest(separators=(first, second)):
                payload = "[ \n" + records[0] + first + "\n" + records[1] + second + "\n" + records[2] + "\n ]"
                result = self.run_sampler(environment={"FAKE_PAYLOAD": payload})
                self.assertEqual(result.returncode, 0, result.stderr)
                escaped = label.replace("\\", "\\\\").replace("\n", "\\n").replace('"', '\\"')
                self.assertIn(f'engine="{escaped}"}} 31.5', self.read_output())

    def test_invalid_sample_framing_and_corruption_fail_closed(self):
        self.add_card("card2", "0x8086")
        samples = real_schema_samples()
        for sample in samples:
            sample["clients"] = {}
        records = [json.dumps(sample) for sample in samples]
        valid = "[" + ",".join(records) + "]"
        missing_commas = "[" + "\n".join(records) + "]"
        payloads = {
            "missing array end": missing_commas[:-1],
            "incomplete final object": "[" + records[0] + records[1] + records[2][:-1] + "]",
            "trailing garbage": missing_commas + " garbage",
            "trailing comma": valid[:-1] + ",]",
            "extra comma": "[" + records[0] + ",," + records[1] + "," + records[2] + "]",
            "missing sample": "[" + records[0] + records[1] + "]",
            "extra sample": missing_commas[:-1] + records[2] + "]",
            "nonobject sample": "[null," + records[1] + "," + records[2] + "]",
            "no array": "\n".join(records),
            "nested missing comma": missing_commas.replace('"busy": 1.0,', '"busy": 1.0', 1),
        }
        for clients in (None, {"123": {}}, [], False):
            previous = dict(samples[0])
            if clients is None:
                del previous["clients"]
            else:
                previous["clients"] = clients
            payloads[f"invalid previous clients {clients}"] = "[" + json.dumps(previous) + records[1] + records[2] + "]"
        for constant in ("NaN", "Infinity", "-Infinity", "1e999"):
            payloads[f"nonfinite {constant}"] = missing_commas.replace('"clients": {}', f'"other": {constant}, "clients": {{}}', 1)
        for name, payload in payloads.items():
            with self.subTest(case=name):
                self.assertEqual(self.run_sampler().returncode, 0)
                prior_timestamp = next(line for line in self.read_output().splitlines()
                                       if line.startswith("server_intel_gpu_last_success_timestamp_seconds"))
                result = self.run_sampler(environment={"FAKE_PAYLOAD": payload})
                self.assertNotEqual(result.returncode, 0, result.stderr)
                text = self.read_output()
                self.assertNotIn("server_intel_gpu_engine_busy_percent", text)
                self.assertIn("server_intel_gpu_sample_success 0\n", text)
                self.assertIn(prior_timestamp, text)

    def test_intel_cards_are_numerically_sorted_and_non_intel_cards_are_ignored(self):
        self.add_card("card10", "0x8086")
        self.add_card("card2", "0x8086")
        self.add_card("card1", "0x1002")
        log = self.root / "calls.jsonl"
        result = self.run_sampler(environment={"FAKE_CALL_LOG": str(log)})

        self.assertEqual(result.returncode, 0, result.stderr)
        calls = [json.loads(line) for line in log.read_text().splitlines()]
        self.assertEqual(calls, [
            ["-J", "-n", "3", "-s", "1000", "-d", "drm:/dev/dri/card2"],
            ["-J", "-n", "3", "-s", "1000", "-d", "drm:/dev/dri/card10"],
        ])
        text = self.read_output()
        self.assertIn('device="card2"', text)
        self.assertIn('device="card10"', text)
        self.assertNotIn('device="card1"', text)

    def test_prometheus_label_escaping(self):
        self.add_card("card2", "0x8086")
        payload = real_schema_samples(10.0, 'copy\\name"line\nnext')
        result = self.run_sampler(environment={"FAKE_PAYLOAD": json.dumps(payload)})

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('engine="copy\\\\name\\"line\\nnext"', self.read_output())

    def test_malformed_or_truncated_json_removes_stale_utilization(self):
        self.add_card("card2", "0x8086")
        self.assertEqual(self.run_sampler().returncode, 0)
        prior_timestamp = next(line for line in self.read_output().splitlines()
                               if line.startswith("server_intel_gpu_last_success_timestamp_seconds"))

        result = self.run_sampler(environment={"FAKE_PAYLOAD": '[{"engines": '})
        self.assertNotEqual(result.returncode, 0)
        text = self.read_output()
        self.assertNotIn("server_intel_gpu_engine_busy_percent", text)
        self.assertIn("server_intel_gpu_sample_success 0", text)
        self.assertIn(prior_timestamp, text)

    def test_nonfinite_and_out_of_range_busy_values_fail_closed(self):
        self.add_card("card2", "0x8086")
        for value in (float("nan"), float("inf"), -0.01, 100.01):
            with self.subTest(value=value):
                self.environment["FAKE_PAYLOAD"] = json.dumps(real_schema_samples(value))
                result = self.run_sampler()
                self.assertNotEqual(result.returncode, 0)
                text = self.read_output()
                self.assertIn("server_intel_gpu_sample_success 0", text)
                self.assertNotIn("server_intel_gpu_engine_busy_percent", text)

    def test_timeout_and_command_error_emit_failure_metrics(self):
        self.add_card("card2", "0x8086")
        for mode, timeout in (("sleep", 0.05), ("error", 1.0)):
            with self.subTest(mode=mode):
                result = self.run_sampler(timeout=timeout, environment={"FAKE_MODE": mode})
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("server_intel_gpu_sample_success 0", self.read_output())
                self.assertNotIn("server_intel_gpu_engine_busy_percent", self.read_output())

    def test_no_intel_device_emits_failure_metrics(self):
        self.add_card("card4", "0x10de")
        result = self.run_sampler()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.read_output(), "server_intel_gpu_sample_success 0\n")

    def test_output_replacement_is_atomic_and_lock_contention_does_not_replace_it(self):
        self.add_card("card2", "0x8086")
        self.output.parent.mkdir(parents=True)
        self.output.write_text("old complete scrape\n")
        lock_path = Path(str(self.output) + ".lock")
        with lock_path.open("w") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            result = self.run_sampler()
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.read_output(), "old complete scrape\n")

        result = self.run_sampler()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("old complete scrape", self.read_output())
        self.assertEqual(list(self.output.parent.glob(".intel-gpu.prom.*.tmp")), [])
        self.assertEqual(self.output.stat().st_mode & 0o777, 0o644)


if __name__ == "__main__":
    unittest.main()
