"""BigTasty NAS backup jobs: evaluated unit boundary plus the real job scripts.

Run through the compute queue (see the flake check notes in the PR); no server,
NAS or secret is touched. The scripts run against scratch directories, with the
mount point check stubbed and every real path rewritten away first.
"""

import json
import os
import re
import shutil
import stat
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
JOBS = ("immichSync", "sharesSync")

# The flake check evaluates the fixture outside the sandbox and passes the JSON
# in BACKUP_JOBS_TEST_CONFIG, with the jobs' PATH packages already in its store;
# run standalone, the test evaluates the fixture and realises them itself.
FIXTURE = ROOT / "hosts/bigtasty/tests/backup-jobs.nix"
EXPR = f"import {FIXTURE} {{ flake = builtins.getFlake (toString {ROOT}); }}"

ASSIGN = re.compile(r'^(SRC|DEST)="([^"]*)"$', re.M)


def assigned(script):
    return {k: v for k, v in ASSIGN.findall(script)}


def realise_path(path_env):
    dirs = [d for d in path_env.split(":") if d.startswith("/nix/store/")]
    if os.environ.get("BACKUP_JOBS_TEST_CONFIG"):
        return dirs
    roots = sorted({"/".join(d.split("/")[:4]) for d in dirs})
    subprocess.run(["nix-store", "--realise", *roots], cwd=ROOT, text=True,
                   capture_output=True, check=True)
    return dirs


class Evaluated(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        precomputed = os.environ.get("BACKUP_JOBS_TEST_CONFIG")
        if precomputed:
            cls.c = json.loads(Path(precomputed).read_text())
            return
        result = subprocess.run(
            ["nix", "eval", "--impure", "--json", "--expr", EXPR],
            cwd=ROOT, text=True, capture_output=True, check=False,
        )
        if result.returncode:
            raise RuntimeError(result.stderr)
        cls.c = json.loads(result.stdout)


class UnitBoundaryTests(Evaluated):
    def test_jobs_are_mount_dependent_periodic_oneshots(self):
        for name in JOBS:
            with self.subTest(job=name):
                job = self.c["jobs"][name]
                self.assertEqual(job["type"], "oneshot")
                self.assertIsNone(job["restart"])
                self.assertNotIn("multi-user.target", job["wantedBy"])
                self.assertIn("/mnt/Backup", job["mounts"])
                self.assertNotIn("inotifywait", job["script"])
                self.assertIn("timers.target", job["timerWantedBy"])
                # A run shortly after boot, then again after every run ends.
                self.assertIn("OnBootSec", job["timer"])
                self.assertIn("OnUnitInactiveSec", job["timer"])

    def test_source_and_destination_roots_are_distinct(self):
        v = {n: assigned(self.c["jobs"][n]["script"]) for n in JOBS}
        for n in JOBS:
            self.assertEqual(set(v[n]), {"SRC", "DEST"}, n)
            self.assertEqual(v[n]["DEST"], "/mnt/Backup")
            # Both ends must be mounted, so an unmounted /RAID cannot leave an
            # empty underlying directory for rsync --delete to mirror.
            self.assertIn(v[n]["DEST"], self.c["jobs"][n]["mounts"])
            self.assertIn(v[n]["SRC"], self.c["jobs"][n]["mounts"])
        # Layout stays /mnt/Backup/<basename of SRC>, as the old jobs wrote it.
        a, b = (v[n]["SRC"].rstrip("/") + "/" for n in JOBS)
        self.assertFalse(a.startswith(b) or b.startswith(a))
        self.assertNotEqual(*(Path(v[n]["SRC"]).name for n in JOBS))

    def test_live_postgres_directory_is_inside_source_and_dumps_are_too(self):
        src = assigned(self.c["jobs"]["immichSync"]["script"])["SRC"]
        # Immich writes its own dumps under the uploads volume (UPLOAD_LOCATION/backups).
        server = [x.split(":")[0] for x in self.c["immichVolumes"]]
        self.assertIn(src + "/uploads", server)
        pg = [x.split(":")[0] for x in self.c["postgresVolumes"]]
        self.assertEqual(pg, [src + "/postgres"])  # the excluded path must match this


class ScriptTests(Evaluated):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="backup-jobs-", dir=os.environ.get("TMPDIR")))
        self.addCleanup(shutil.rmtree, self.tmp, True)
        self.src = self.tmp / "data/apps/immich"
        self.shares = self.tmp / "data/shares"
        self.mount = self.tmp / "backup"
        self.mount.mkdir()

    def file(self, path, text="x", age_hours=None):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        if age_hours is not None:
            t = time.time() - age_hours * 3600
            os.utime(path, (t, t))
        return path

    def gz(self, path, age_hours=None):
        import gzip
        path.parent.mkdir(parents=True, exist_ok=True)
        with gzip.open(path, "wb") as fh:
            fh.write(b"-- dump")
        if age_hours is not None:
            t = time.time() - age_hours * 3600
            os.utime(path, (t, t))
        return path

    def run_job(self, name, src, mounted=True):
        job = self.c["jobs"][name]
        script = job["script"]
        dest = self.mount / Path(src).name
        repl = {"SRC": str(src), "DEST": str(self.mount)}
        script = ASSIGN.sub(lambda m: f'{m.group(1)}="{repl[m.group(1)]}"', script)
        # Never let a rewrite miss reach the real server paths.
        self.assertNotIn("/RAID", script)
        self.assertNotIn("/mnt/Backup", script)
        shebang = script.splitlines()[0]
        stub = self.tmp / "stub"
        stub.mkdir(exist_ok=True)
        mp = stub / "mountpoint"
        mp.write_text(f'{shebang}\n[ "$FAKE_MOUNTED" = 1 ]\n')
        mp.chmod(mp.stat().st_mode | stat.S_IXUSR)
        run = self.tmp / "job.sh"
        run.write_text(script)
        run.chmod(run.stat().st_mode | stat.S_IXUSR)
        dirs = realise_path(job["path"])
        env = {"PATH": ":".join([str(stub), *dirs]), "FAKE_MOUNTED": "1" if mounted else "0"}
        return subprocess.run([str(run)], env=env, text=True, capture_output=True, cwd=self.tmp), dest

    # --- Immich -----------------------------------------------------------

    def immich_tree(self):
        self.file(self.src / "uploads/library/a.jpg", "photo")
        self.file(self.src / "uploads/upload/b.mp4", "video")
        self.file(self.src / "postgres/PG_VERSION", "14")

    def test_immich_refuses_to_copy_when_backup_is_not_mounted(self):
        self.immich_tree()
        r, dest = self.run_job("immichSync", self.src, mounted=False)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn(str(self.mount), r.stderr)
        self.assertFalse(dest.exists())

    def test_immich_mirrors_media_and_excludes_live_postgres(self):
        self.immich_tree()
        self.gz(self.src / "uploads/backups/immich-db-backup-1.sql.gz", age_hours=1)
        r, dest = self.run_job("immichSync", self.src)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual((dest / "uploads/library/a.jpg").read_text(), "photo")
        self.assertTrue((dest / "uploads/backups/immich-db-backup-1.sql.gz").exists())
        self.assertFalse((dest / "postgres").exists())

    def test_immich_keeps_an_existing_nas_postgres_copy(self):
        self.immich_tree()
        self.gz(self.src / "uploads/backups/immich-db-backup-1.sql.gz", age_hours=1)
        old = self.file(self.mount / "immich/postgres/PG_VERSION", "old raw copy")
        r, _ = self.run_job("immichSync", self.src)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(old.read_text(), "old raw copy")

    def test_immich_mirror_follows_deletions(self):
        self.immich_tree()
        self.gz(self.src / "uploads/backups/immich-db-backup-1.sql.gz", age_hours=1)
        self.file(self.mount / "immich/uploads/library/gone.jpg")
        r, dest = self.run_job("immichSync", self.src)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertFalse((dest / "uploads/library/gone.jpg").exists())

    def test_immich_without_a_dump_copies_media_but_fails_loudly(self):
        self.immich_tree()
        r, dest = self.run_job("immichSync", self.src)
        self.assertNotEqual(r.returncode, 0)
        self.assertTrue((dest / "uploads/library/a.jpg").exists())
        self.assertIn("no usable", r.stderr.lower())
        # A freshness/integrity failure, not a claim about restorability.
        self.assertIn("freshness", r.stderr.lower())
        self.assertNotIn("recoverable", r.stderr.lower())

    def test_immich_ignores_partial_stale_and_corrupt_dumps(self):
        self.immich_tree()
        self.file(self.src / "uploads/backups/immich-db-backup-2.sql.gz.tmp", "partial", age_hours=0)
        self.gz(self.src / "uploads/backups/immich-db-backup-old.sql.gz", age_hours=24 * 5)
        r, dest = self.run_job("immichSync", self.src)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("no usable", r.stderr.lower())
        self.assertNotIn("recoverable", r.stderr.lower())
        self.assertFalse((dest / "uploads/backups/immich-db-backup-2.sql.gz.tmp").exists())
        self.file(self.src / "uploads/backups/immich-db-backup-3.sql.gz", "not gzip", age_hours=1)
        r, _ = self.run_job("immichSync", self.src)
        self.assertNotEqual(r.returncode, 0)

    # --- Shares -----------------------------------------------------------

    def test_shares_refuses_when_backup_is_not_mounted(self):
        self.file(self.shares / "Files/a.txt")
        r, dest = self.run_job("sharesSync", self.shares, mounted=False)
        self.assertNotEqual(r.returncode, 0)
        self.assertFalse(dest.exists())

    def test_shares_mirrors_files_and_follows_deletions(self):
        self.file(self.shares / "Files/a.txt", "a")
        self.file(self.mount / "shares/Files/gone.txt")
        r, dest = self.run_job("sharesSync", self.shares)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual((dest / "Files/a.txt").read_text(), "a")
        self.assertFalse((dest / "Files/gone.txt").exists())

    def test_shares_with_missing_source_deletes_nothing(self):
        self.file(self.mount / "shares/Files/keep.txt")
        r, dest = self.run_job("sharesSync", self.tmp / "gone/shares")
        self.assertNotEqual(r.returncode, 0)
        self.assertTrue((dest / "Files/keep.txt").exists())


if __name__ == "__main__":
    unittest.main()
