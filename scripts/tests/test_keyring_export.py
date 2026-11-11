"""keyring-export.py CLI: the plaintext dump must never reuse or follow a path.

A dummy `secretstorage` package (first on PYTHONPATH) stands in for the real
keyring, so no credentials or system bus are touched.
Run: python3 -m unittest discover -s scripts/tests -v
"""

import json
import os
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "keyring-export.py"

DUMMY = '''
import os

def _touch():
    with open(os.environ["DUMMY_CONTACT_LOG"], "a") as f:
        f.write("contacted\\n")

def dbus_init():
    _touch()
    # Simulate another process planting the destination while we talk to the keyring.
    plant = os.environ.get("DUMMY_PLANT")
    if plant:
        os.symlink(os.environ["DUMMY_PLANT_TARGET"], plant)
    return object()

class _Item:
    def get_label(self): return "item"
    def get_attributes(self): return {"k": "v"}
    def get_secret_content_type(self): return "text/plain"
    def get_secret(self): return b"hunter2"

class _Collection:
    def is_locked(self): return False
    def get_label(self): return "login"
    def get_all_items(self): return [_Item()]

def get_all_collections(connection):
    return [_Collection()]
'''


class KeyringExport(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory(dir=os.environ.get("TMPDIR"))
        self.addCleanup(tmp.cleanup)
        self.dir = Path(tmp.name)
        (self.dir / "dummy").mkdir()
        (self.dir / "dummy" / "secretstorage.py").write_text(DUMMY)
        self.contact_log = self.dir / "contact.log"
        self.out = self.dir / "export.json"

    def run_export(self, path=None, umask=0o022, **env):
        return subprocess.run(
            [sys.executable, str(SCRIPT), str(path or self.out)],
            capture_output=True, text=True,
            preexec_fn=lambda: os.umask(umask),
            env={**os.environ, "PYTHONPATH": str(self.dir / "dummy"),
                 "DUMMY_CONTACT_LOG": str(self.contact_log), **env},
        )

    def assert_refused_without_contact(self, result):
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(str(self.out), result.stderr)
        self.assertFalse(self.contact_log.exists(), "keyring was contacted")

    def test_existing_world_readable_file_is_refused_untouched(self):
        self.out.write_text("old")
        self.out.chmod(0o644)
        result = self.run_export()
        self.assert_refused_without_contact(result)
        self.assertEqual(self.out.read_text(), "old")
        self.assertEqual(stat.S_IMODE(self.out.stat().st_mode), 0o644)

    def test_dangling_symlink_is_refused_and_not_followed(self):
        target = self.dir / "elsewhere"
        self.out.symlink_to(target)
        self.assert_refused_without_contact(self.run_export())
        self.assertFalse(target.exists())

    def test_symlink_to_existing_file_is_refused_and_target_untouched(self):
        target = self.dir / "target"
        target.write_text("precious")
        self.out.symlink_to(target)
        self.assert_refused_without_contact(self.run_export())
        self.assertEqual(target.read_text(), "precious")

    def test_new_file_is_0600_even_with_permissive_umask(self):
        result = self.run_export(umask=0o000)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(stat.S_IMODE(self.out.stat().st_mode), 0o600)
        dump = json.loads(self.out.read_text())
        self.assertEqual(dump["collections"][0]["items"][0]["secret"], "hunter2")

    def test_destination_planted_during_export_is_not_followed(self):
        target = self.dir / "elsewhere"
        result = self.run_export(DUMMY_PLANT=str(self.out), DUMMY_PLANT_TARGET=str(target))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(str(self.out), result.stderr)
        self.assertFalse(target.exists(), "secrets were written through the symlink")


if __name__ == "__main__":
    unittest.main()
