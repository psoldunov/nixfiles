"""convert_all_to_webp: behavior of the script the home-manager module builds.

The script body is taken from modules/home/workstation/scripts.nix by evaluating
the module against a stub pkgs (no builds). ImageMagick is a fake `magick`.
Run: python3 -m unittest discover -s scripts/tests -v
"""

import os
import re
import shutil
import stat
import subprocess
import tempfile
import threading
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

# The flake check evaluates the fixture outside the sandbox and passes the
# script text in CONVERT_ALL_TO_WEBP_SCRIPT; run standalone, the test does it.
FIXTURE = ROOT / "scripts/tests/convert-all-to-webp-script.nix"
EXPR = f"import {FIXTURE} {{ flake = builtins.getFlake (toString {ROOT}); }}"

# Fake ImageMagick: `magick IN webp:-` writes the image to stdout, which the
# script points at a file it owns. Any other output argument is a regression
# (the script must never hand ImageMagick a filename), and like the real thing
# the fake expands %d in one to the scene number, so the old bug is visible.
# FAKE_MAGICK_FAIL=<name> fails for that input after writing partial output.
FAKE_MAGICK = """#!BASH
in="$1"; out="$2"
echo "$in" >> "$FAKE_MAGICK_LOG"
[ -n "${FAKE_MAGICK_SLEEP:-}" ] && sleep "$FAKE_MAGICK_SLEEP"
if [ "$out" != "webp:-" ]; then
    out="${out#webp:}"; out="${out//%d/0}"
    echo "webp-of:$in" > "$out"
    exit 0
fi
echo "webp-of:$in"
[ "${in#./}" = "${FAKE_MAGICK_FAIL:-}" ] && exit 1
exit 0
"""

# The friendly check in front of the claim; stripping it leaves the claim alone.
PREFLIGHT = re.compile(r'    if \[ -e "\$dest" \].*?\n    fi\n', re.DOTALL)


def script_text(fake_bin: Path) -> str:
    precomputed = os.environ.get("CONVERT_ALL_TO_WEBP_SCRIPT")
    text = Path(precomputed).read_text() if precomputed else subprocess.run(
        ["nix", "eval", "--impure", "--raw", "--expr", EXPR],
        check=True, capture_output=True, text=True,
    ).stdout
    return text.replace("FAKE", str(fake_bin))


def build_script(fake_bin: Path, workdir: Path) -> Path:
    magick = fake_bin / "bin" / "magick"
    magick.parent.mkdir(parents=True)
    # No /usr/bin/env in the flake check sandbox: name bash directly.
    bash = shutil.which("bash")
    assert bash, "bash must be installed to run the converter tests"
    magick.write_text(FAKE_MAGICK.replace("BASH", bash, 1))
    magick.chmod(magick.stat().st_mode | stat.S_IXUSR)
    script = workdir.parent / "convert_all_to_webp.sh"
    script.write_text(script_text(fake_bin))
    return script


class ConvertAllToWebp(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls._tmp = tempfile.TemporaryDirectory(dir=os.environ.get("TMPDIR"))
        cls.base = Path(cls._tmp.name)
        cls.fake_bin = cls.base / "fake"
        cls.script = build_script(cls.fake_bin, cls.base / "x")

    @classmethod
    def tearDownClass(cls):
        cls._tmp.cleanup()

    def setUp(self):
        self._work = tempfile.TemporaryDirectory(dir=self.base)
        self.dir = Path(self._work.name)
        self.log = self.dir.parent / (self.dir.name + ".log")
        self.addCleanup(self._work.cleanup)

    def run_script(self, **env):
        return subprocess.run(
            ["bash", str(self.script)], cwd=self.dir, capture_output=True, text=True,
            env={**os.environ, "FAKE_MAGICK_LOG": str(self.log), **env},
        )

    def test_jpg_and_png_of_same_name_do_not_overwrite_each_other(self):
        (self.dir / "photo.jpg").write_text("jpg")
        (self.dir / "photo.png").write_text("png")
        result = self.run_script()
        self.assertNotEqual(result.returncode, 0)
        # the first original converts; the colliding one is refused and kept
        self.assertTrue((self.dir / "photo.webp").read_text().strip().endswith("photo.jpg"))
        self.assertFalse((self.dir / "photo.jpg").exists())
        self.assertEqual((self.dir / "photo.png").read_text(), "png")

    def test_successful_conversion_replaces_original_and_exits_zero(self):
        (self.dir / "a.b.gif").write_text("gif")
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.dir / "a.b.webp").read_text().strip().endswith("a.b.gif"))
        self.assertFalse((self.dir / "a.b.gif").exists())

    def test_leading_dash_source_is_removed_after_success(self):
        (self.dir / "-good.png").write_text("png")
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.dir / "-good.png").exists(), result.stderr)
        self.assertTrue((self.dir / "-good.webp").exists())

    def test_leading_dash_failed_output_is_removed_and_source_kept(self):
        (self.dir / "-bad.png").write_text("png")
        result = self.run_script(FAKE_MAGICK_FAIL="-bad.png")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((self.dir / "-bad.png").read_text(), "png")
        self.assertFalse((self.dir / "-bad.webp").exists(), result.stderr)

    def test_existing_webp_is_kept_and_input_preserved(self):
        (self.dir / "photo.png").write_text("png")
        (self.dir / "photo.webp").write_text("precious")
        result = self.run_script()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("photo.webp", result.stderr)
        self.assertEqual((self.dir / "photo.webp").read_text(), "precious")
        self.assertEqual((self.dir / "photo.png").read_text(), "png")
        self.assertFalse(self.log.exists(), "magick must not run for a refused input")

    def test_dangling_symlink_destination_is_refused(self):
        (self.dir / "photo.png").write_text("png")
        elsewhere = self.dir / "elsewhere"
        (self.dir / "photo.webp").symlink_to(elsewhere)
        result = self.run_script()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(elsewhere.exists(), "write followed the symlink")
        self.assertTrue((self.dir / "photo.webp").is_symlink())
        self.assertEqual((self.dir / "photo.png").read_text(), "png")

    def test_symlink_to_existing_file_destination_is_refused(self):
        (self.dir / "photo.png").write_text("png")
        target = self.dir / "target"
        target.write_text("precious")
        (self.dir / "photo.webp").symlink_to(target)
        result = self.run_script()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(target.read_text(), "precious")
        self.assertEqual((self.dir / "photo.png").read_text(), "png")

    def test_percent_d_in_the_name_never_reaches_another_file(self):
        # magick expands %d in an output *name* to a scene number, so a name
        # handed to it would write b0.webp over a file the guard never saw.
        (self.dir / "b%d.png").write_text("png")
        (self.dir / "b0.webp").write_text("precious")
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.dir / "b0.webp").read_text(), "precious")
        self.assertTrue((self.dir / "b%d.webp").read_text().strip().endswith("b%d.png"))
        self.assertFalse((self.dir / "b%d.png").exists())

    def test_prefix_like_names_convert_in_place(self):
        (self.dir / "webp:x.png").write_text("png")
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.dir / "webp:x.webp").read_text().strip().endswith("webp:x.png"))

    def test_failed_claim_never_removes_a_foreign_destination(self):
        # Without the friendly check, only the atomic claim stands between the
        # script and a file that appeared at the destination: it must refuse,
        # keep the input, and leave that file (or symlink target) alone.
        text = script_text(self.fake_bin)
        stripped = PREFLIGHT.sub("", text, count=1)
        self.assertNotEqual(stripped, text, "the preflight check moved; update PREFLIGHT")
        script = self.base / "no-preflight.sh"
        script.write_text(stripped)
        (self.dir / "a.png").write_text("png")
        (self.dir / "a.webp").write_text("precious")
        (self.dir / "b.png").write_text("png")
        target = self.dir / "target"
        target.write_text("precious")
        (self.dir / "b.webp").symlink_to(target)
        (self.dir / "c.png").write_text("png")
        (self.dir / "c.webp").symlink_to(self.dir / "elsewhere")
        result = subprocess.run(
            ["bash", str(script)], cwd=self.dir, capture_output=True, text=True,
            env={**os.environ, "FAKE_MAGICK_LOG": str(self.log)},
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((self.dir / "a.webp").read_text(), "precious")
        self.assertEqual(target.read_text(), "precious")
        self.assertTrue((self.dir / "b.webp").is_symlink())
        self.assertTrue((self.dir / "c.webp").is_symlink())
        self.assertFalse((self.dir / "elsewhere").exists(), "write followed the symlink")
        for name in ("a", "b", "c"):
            self.assertEqual((self.dir / f"{name}.png").read_text(), "png")
        self.assertFalse(self.log.exists(), "magick must not run when the claim fails")

    def test_failed_conversion_keeps_input_and_leaves_no_partial_output(self):
        (self.dir / "bad.png").write_text("png")
        (self.dir / "good.png").write_text("png")
        result = self.run_script(FAKE_MAGICK_FAIL="bad.png")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((self.dir / "bad.png").read_text(), "png")
        self.assertFalse((self.dir / "bad.webp").exists())
        # one bad image does not stop the rest
        self.assertTrue((self.dir / "good.webp").exists())
        self.assertFalse((self.dir / "good.png").exists())

    def test_concurrent_runs_never_clobber_or_double_consume(self):
        (self.dir / "photo.jpg").write_text("jpg")
        (self.dir / "photo.png").write_text("png")
        results = []

        def go():
            results.append(self.run_script(FAKE_MAGICK_SLEEP="0.5"))

        threads = [threading.Thread(target=go) for _ in range(2)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()
        self.assertEqual(self.log.read_text().count("\n"), 1, "magick ran more than once")
        self.assertTrue((self.dir / "photo.webp").read_text().strip().endswith("photo.jpg"))
        self.assertEqual((self.dir / "photo.png").read_text(), "png")


if __name__ == "__main__":
    unittest.main()
