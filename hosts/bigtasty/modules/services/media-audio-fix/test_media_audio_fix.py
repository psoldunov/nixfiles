#!/usr/bin/env python3
"""Tests for media-audio-fix.py through main(), with stub ffprobe and ffmpeg.

Every file is a dummy in a temp directory; nothing reads or encodes media.
"""

import fcntl
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

SCRIPT = Path(__file__).resolve().parent / "media-audio-fix.py"

# One video and one DTS track: the plan converts the DTS track to AC3.
SOURCE_PROBE = {
    "streams": [
        {"index": 0, "codec_type": "video", "codec_name": "h264", "disposition": {"default": 1}},
        {"index": 1, "codec_type": "audio", "codec_name": "dts", "channels": 6,
         "tags": {"language": "eng"}, "disposition": {"default": 1}},
    ],
    "format": {"duration": "100.0"},
}
OUTPUT_PROBE = {
    "streams": [
        {"index": 0, "codec_type": "video", "codec_name": "h264", "disposition": {"default": 1}},
        {"index": 1, "codec_type": "audio", "codec_name": "ac3", "channels": 6,
         "tags": {"language": "eng"}, "disposition": {"default": 1}},
    ],
    "format": {"duration": "100.0"},
}

# ffprobe: the source probe for library files, the output probe for temp files.
FFPROBE = f"""#!{sys.executable}
import json, sys
path = sys.argv[-1]
print(json.dumps({OUTPUT_PROBE!r} if ".audiofix" in path else {SOURCE_PROBE!r}))
"""

# ffmpeg: writes "encoded:<input bytes>" to the output. With FAKE_IMPORT set,
# a new file replaces the input mid-encode, as a Sonarr/Radarr import would.
FFMPEG = f"""#!{sys.executable}
import os, sys
src = sys.argv[sys.argv.index("-i") + 1]
out = sys.argv[-1]
data = open(src, "rb").read()
if os.environ.get("FAKE_IMPORT"):
    with open(src + ".import", "wb") as f:
        f.write(os.environ["FAKE_IMPORT"].encode())
    os.replace(src + ".import", src)
with open(out, "wb") as f:
    f.write(b"encoded:" + data)
"""


def load_script():
    spec = importlib.util.spec_from_file_location("media_audio_fix", SCRIPT)
    assert spec is not None and spec.loader is not None, f"cannot load {SCRIPT}"
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class MediaAudioFixTests(unittest.TestCase):
    def setUp(self):
        tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(tempdir.cleanup)
        self.root = Path(tempdir.name)
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        for name, body in (("ffprobe", FFPROBE), ("ffmpeg", FFMPEG)):
            (bin_dir / name).write_text(body)
            (bin_dir / name).chmod(0o755)
        self.library = self.root / "Movies"
        self.library.mkdir()
        self.lock_dir = self.root / "run"
        self.lock_dir.mkdir()
        self.script = load_script()
        self.enterContext(mock.patch.multiple(
            self.script, ROOTS=[str(self.library)], LOCK_DIR=str(self.lock_dir)))
        env = {"PATH": f"{bin_dir}{os.pathsep}{os.environ['PATH']}"}
        patcher = mock.patch.dict(os.environ, env)
        patcher.start()
        self.addCleanup(patcher.stop)

    def movie(self, content=b"old release"):
        path = self.library / "Film (2001).mkv"
        path.write_bytes(content)
        path.chmod(0o640)
        os.utime(path, (1, 1))  # old enough to be past the import grace period
        return path

    def run_main(self, *args):
        with (
            mock.patch.object(sys, "argv", ["media-audio-fix", *map(str, args)]),
            mock.patch("builtins.print") as printed,
        ):
            code = self.script.main()
        self.output = "\n".join(str(call.args[0]) for call in printed.call_args_list)
        return code

    def hidden_files(self):
        return sorted(p.name for p in self.library.iterdir() if p.name.startswith("."))

    def test_missing_arr_settings_are_rejected_before_any_request(self):
        config = self.root / "config.xml"
        for contents in ("<Config><Port>8989</Port></Config>",
                         "<Config><ApiKey>dummy</ApiKey></Config>"):
            with self.subTest(contents=contents):
                config.write_text(contents)
                with (
                    mock.patch.object(self.script.urllib.request, "urlopen",
                                      side_effect=AssertionError("invalid config reached the network")) as request,
                    self.assertRaisesRegex(ValueError, "ApiKey or Port"),
                ):
                    self.script.arr_titles(config, "series")
                request.assert_not_called()

    def test_unchanged_file_is_replaced_by_the_checked_output(self):
        path = self.movie()
        code = self.run_main(path)
        self.assertEqual(path.read_bytes(), b"encoded:old release")
        self.assertEqual(path.stat().st_mode & 0o777, 0o640)
        self.assertEqual(self.hidden_files(), [])
        self.assertEqual(code, 0)

    def test_dry_run_of_the_library_changes_nothing(self):
        path = self.movie()
        busy = self.library / ".Other (1999).mkv.audiofix.tmp"
        busy.write_bytes(b"another run's output in progress")
        self.run_main("--dry-run")
        self.assertEqual(busy.read_bytes(), b"another run's output in progress")
        self.assertEqual(path.read_bytes(), b"old release")

    def test_real_run_stops_while_another_run_holds_the_lock(self):
        path = self.movie()
        busy = self.library / ".Other (1999).mkv.audiofix.tmp"
        busy.write_bytes(b"another run's output in progress")
        other_run = os.open(self.lock_dir, os.O_RDONLY)
        self.addCleanup(os.close, other_run)
        fcntl.flock(other_run, fcntl.LOCK_EX)
        code = self.run_main()
        self.assertEqual(code, 1)
        self.assertEqual(busy.read_bytes(), b"another run's output in progress")
        self.assertEqual(path.read_bytes(), b"old release")

    def test_rewrite_leaves_a_temp_file_it_did_not_create_alone(self):
        path = self.movie()
        foreign = self.library / f".{path.name}.audiofix.tmp"
        foreign.write_bytes(b"not ours")
        code = self.run_main(path)
        self.assertEqual(code, 0)
        self.assertEqual(path.read_bytes(), b"encoded:old release")
        self.assertEqual(foreign.read_bytes(), b"not ours")
        self.assertEqual(self.hidden_files(), [foreign.name])

    def test_import_landing_during_the_swap_keeps_both_files(self):
        path = self.movie()
        real_rename = os.rename

        def rename_then_import(src, dst):
            real_rename(src, dst)
            if dst.endswith(".audiofix.held"):  # the instant the library file is aside
                path.write_bytes(b"new release")

        with mock.patch("os.rename", rename_then_import):
            code = self.run_main(path)
        self.assertEqual(code, 1)
        self.assertEqual(path.read_bytes(), b"new release")
        held = [p for p in self.library.iterdir() if p.name.endswith(".audiofix.held")]
        self.assertEqual([p.read_bytes() for p in held], [b"old release"])

    def contents(self):
        return {p.read_bytes() for p in self.library.iterdir()}

    def run_with_link_failure_and_import(self, failing_link_calls):
        """Hard links fail on the given calls (1-based); an import lands once a file is held."""
        path = self.movie()
        real_rename, real_link = os.rename, os.link
        calls, written = [], {b"old release"}

        def rename_then_import(src, dst):
            real_rename(src, dst)
            if dst.endswith(".audiofix.held") and not path.exists():
                path.write_bytes(b"new release")
                written.add(b"new release")

        def link(src, dst):
            calls.append(dst)
            if len(calls) in failing_link_calls:
                raise PermissionError(1, "Operation not permitted")
            real_link(src, dst)

        with mock.patch("os.rename", rename_then_import), mock.patch("os.link", link):
            code = self.run_main(path)
        self.assertEqual(code, 1)
        self.assertLessEqual(written, self.contents())  # no version is lost
        return path

    def test_share_without_hard_links_loses_nothing(self):
        path = self.run_with_link_failure_and_import(failing_link_calls=range(1, 10))
        self.assertTrue(path.exists())

    def test_link_error_during_the_swap_loses_neither_file(self):
        path = self.run_with_link_failure_and_import(failing_link_calls={2})
        self.assertEqual(path.read_bytes(), b"new release")

    def test_a_held_copy_from_an_earlier_run_blocks_the_rewrite(self):
        path = self.movie()
        earlier = self.library / f".{path.name}.k3j9x2ab.audiofix.held"
        earlier.write_bytes(b"recovery copy")
        code = self.run_main(path)
        self.assertEqual(code, 1)
        self.assertEqual(path.read_bytes(), b"old release")
        self.assertEqual(earlier.read_bytes(), b"recovery copy")
        self.assertEqual(self.hidden_files(), [earlier.name])

    def test_a_library_file_left_only_as_a_held_copy_is_reported_with_the_fix(self):
        path = self.library / "Ocean's Eleven (2001).mkv"
        held = self.library / f".{path.name}.k3j9x2ab.audiofix.held"
        held.write_bytes(b"the only copy")
        self.assertEqual(self.run_main("--dry-run"), 1)
        self.assertEqual(self.run_main(), 1)  # a real run fails too, and leaves it alone
        self.assertEqual(held.read_bytes(), b"the only copy")
        self.assertEqual(self.hidden_files(), [held.name])
        self.assertIn(f"missing: {path}", self.output)
        command = self.output.split("restore it with: ", 1)[1].splitlines()[0]
        subprocess.run(["sh", "-c", command], check=True)  # the printed fix works as given
        self.assertEqual(path.read_bytes(), b"the only copy")

    def test_the_module_creates_the_lock_directory_the_script_uses(self):
        rules = (SCRIPT.parent / "default.nix").read_text()
        self.assertIn(f'"d {load_script().LOCK_DIR} 0755 psoldunov users -"', rules)

    def test_import_during_encode_is_kept_and_not_overwritten(self):
        path = self.movie()
        with mock.patch.dict(os.environ, {"FAKE_IMPORT": "new release"}):
            code = self.run_main(path)
        self.assertEqual(path.read_bytes(), b"new release")
        self.assertEqual(self.hidden_files(), [])
        self.assertEqual(code, 1)


if __name__ == "__main__":
    unittest.main()
