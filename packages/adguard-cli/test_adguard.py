import base64
import http.server
import json
import os
import subprocess
import shlex
import datetime
import tempfile
import threading
import unittest
from unittest import mock

import adguard


class Handler(http.server.BaseHTTPRequestHandler):
    seen = []
    response = {"protection_enabled": True}
    status = 200
    redirect = False
    raw_body = None
    delay = 0

    def do_GET(self):
        self.record()
        if self.delay:
            import time
            time.sleep(self.delay)
        self.send_response(self.status)
        self.end_headers()
        try:
            self.wfile.write(self.raw_body if self.raw_body is not None else json.dumps(self.response).encode())
        except BrokenPipeError:
            pass

    def do_POST(self):
        self.record()
        n = int(self.headers.get("Content-Length", "0"))
        Handler.body = self.rfile.read(n)
        if self.redirect:
            self.send_response(302)
            self.send_header("Location", "http://example.com/")
            self.end_headers()
            return
        self.send_response(self.status)
        self.end_headers()
        self.wfile.write(self.raw_body if self.raw_body is not None else b"OK")

    def record(self):
        Handler.seen.append((self.command, self.path, self.headers.get("Authorization")))

    def log_message(self, *args):
        pass


class CliTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()

    def setUp(self):
        Handler.seen = []
        Handler.status = 200
        Handler.redirect = False
        Handler.raw_body = None
        Handler.delay = 0
        Handler.response = {"protection_enabled": True}
        self.tmp = tempfile.TemporaryDirectory()
        self.cred = os.path.join(self.tmp.name, "credentials.json")
        with open(self.cred, "w") as f:
            json.dump({"username": "user", "password": "secret"}, f)
        os.chmod(self.cred, 0o600)
        self.stat_patch = mock.patch.object(adguard.os, "stat", return_value=type("Stat", (), {"st_uid": 0, "st_mode": 0o100600})())
        self.stat_patch.start()
        self.config = {"mode": "local", "base_url": "http://127.0.0.1:%d" % self.server.server_port,
                       "credentials_file": self.cred, "unbound_control": ["/fake/unbound-control"]}

    def tearDown(self):
        self.stat_patch.stop()
        self.tmp.cleanup()

    def test_pause_units_default_and_validation(self):
        self.assertEqual(adguard.parse_args(["pause"]), ("pause", ["5m"]))
        self.assertEqual(adguard.parse_args(["pause", "2h"]), ("pause", ["2h"]))
        for args in (["pause", "0m"], ["pause", "-1m"], ["pause", "1d"], ["pause", "169h"], ["pause", "1m", "extra"]):
            with self.assertRaises(adguard.CliError):
                adguard.parse_args(args)

    def test_pause_resume_status(self):
        adguard.run(self.config, adguard.parse_args(["pause", "2m"]))
        self.assertEqual(Handler.seen[-1][:2], ("POST", "/control/protection"))
        self.assertEqual(json.loads(Handler.body), {"enabled": False, "duration": 120000})
        adguard.run(self.config, adguard.parse_args(["resume"]))
        self.assertEqual(json.loads(Handler.body), {"enabled": True})
        Handler.response = {"protection_enabled": True, "protection_disabled_until": (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(minutes=5)).isoformat()}
        with mock.patch("builtins.print") as output:
            adguard.run(self.config, adguard.parse_args(["status"]))
            self.assertIn("Protection: paused", output.call_args_list[0].args[0])

    def test_auth(self):
        adguard.run(self.config, ("status", []))
        self.assertEqual(Handler.seen[-1][2], "Basic " + base64.b64encode(b"user:secret").decode())

    def test_unbound_first_and_partial_failure(self):
        events = []
        def fake_run(*args, **kwargs):
            events.append("unbound")
            return mock.Mock(returncode=0)
        with mock.patch.object(adguard.subprocess, "run", side_effect=fake_run), mock.patch.object(adguard, "request", side_effect=lambda *a: events.append("adguard")):
            adguard.run(self.config, ("flush", []))
        self.assertEqual(events, ["unbound", "adguard"])
        with mock.patch.object(adguard.subprocess, "run", return_value=mock.Mock(returncode=1)), mock.patch.object(adguard, "request") as req:
            with self.assertRaises(adguard.CliError):
                adguard.run(self.config, ("flush", []))
            req.assert_not_called()
        with mock.patch.object(adguard.subprocess, "run", return_value=mock.Mock(returncode=0)), mock.patch.object(adguard, "request", side_effect=adguard.CliError("AdGuard HTTP error: status 500")):
            with self.assertRaisesRegex(adguard.CliError, "Unbound cache flushed, but AdGuard cache clear failed"):
                adguard.run(self.config, ("flush", []))

    def test_http_error_and_redirect(self):
        Handler.status = 401
        with self.assertRaisesRegex(adguard.CliError, "HTTP error"):
            adguard.run(self.config, ("status", []))
        Handler.status = 200
        Handler.redirect = True
        with self.assertRaises(adguard.CliError):
            adguard.run(self.config, ("resume", []))

    def test_malformed_status_and_timeout(self):
        with mock.patch.object(adguard, "request", return_value=[]), self.assertRaises(adguard.CliError):
            adguard.run(self.config, ("status", []))
        with mock.patch.object(adguard, "request", side_effect=adguard.CliError("AdGuard request timed out")), self.assertRaises(adguard.CliError):
            adguard.run(self.config, ("status", []))

    def test_remote_argv_and_no_secret_access(self):
        config = {"mode": "remote", "ssh": "/nix/store/openssh/bin/ssh", "target": "pihome"}
        with mock.patch.object(adguard.subprocess, "run", return_value=mock.Mock(returncode=0)) as run:
            adguard.run(config, adguard.parse_args(["pause", "5m"]))
        call = run.call_args.args[0]
        self.assertEqual(call[0], config["ssh"])
        self.assertEqual(shlex.split(call[-1]), ["sudo", "-n", "/run/current-system/sw/bin/adguard", "pause", "5m"])
        self.assertEqual(call[2], "-oConnectTimeout=5")
        self.assertEqual(run.call_args.kwargs["timeout"], 30)
        with mock.patch.object(adguard.subprocess, "run", return_value=mock.Mock(returncode=0)):
            adguard.run(config, ("resume", []))
        self.assertEqual(adguard.parse_args(["--help"])[0], "help")

    def test_plain_ok_mutations_and_malformed_status(self):
        Handler.raw_body = b"OK"
        adguard.run(self.config, ("resume", []))
        with mock.patch.object(adguard.subprocess, "run", return_value=mock.Mock(returncode=0)):
            adguard.run(self.config, ("flush", []))
        Handler.raw_body = b"not json"
        with self.assertRaisesRegex(adguard.CliError, "malformed status JSON"):
            adguard.run(self.config, ("status", []))

    def test_oversized_and_real_timeout(self):
        Handler.raw_body = b"x" * (adguard.MAX_RESPONSE + 1)
        with self.assertRaisesRegex(adguard.CliError, "size limit"):
            adguard.run(self.config, ("status", []))
        Handler.raw_body = None
        Handler.delay = 0.2
        with mock.patch.object(adguard, "TIMEOUT", 0.05):
            with self.assertRaisesRegex(adguard.CliError, "timed out"):
                adguard.run(self.config, ("status", []))

    def test_proxy_disabled_and_credentials_protection(self):
        with mock.patch.object(adguard.urllib.request, "build_opener", wraps=adguard.urllib.request.build_opener) as opener:
            adguard.run(self.config, ("status", []))
            self.assertEqual(opener.call_args.args[0].proxies, {})
        with mock.patch.object(adguard.os, "stat", return_value=type("Stat", (), {"st_uid": 1000, "st_mode": 0o100600})()):
            with self.assertRaisesRegex(adguard.CliError, "root-owned"):
                adguard.run(self.config, ("status", []))

    def test_remote_failure_and_help_no_secret_access(self):
        config = {"mode": "remote", "ssh": "/nix/store/openssh/bin/ssh", "target": "pihome"}
        with mock.patch.object(adguard.subprocess, "run", return_value=mock.Mock(returncode=2)):
            with self.assertRaisesRegex(adguard.CliError, "remote AdGuard command failed"):
                adguard.run(config, ("status", []))
        with mock.patch.object(adguard.subprocess, "run", side_effect=subprocess.TimeoutExpired("ssh", 30)):
            with self.assertRaisesRegex(adguard.CliError, "timed out"):
                adguard.run(config, ("status", []))
        with mock.patch.object(adguard.os, "stat", side_effect=AssertionError("secret accessed")), mock.patch.object(adguard.subprocess, "run", side_effect=AssertionError("ssh accessed")):
            self.assertEqual(adguard.parse_args(["--help"])[0], "help")

    def test_remote_targets_run_each_and_report_failures(self):
        config = {"mode": "remote", "ssh": "/nix/store/openssh/bin/ssh", "targets": ["pihome", "bigtasty"]}
        results = [mock.Mock(returncode=2), mock.Mock(returncode=0)]
        with mock.patch.object(adguard.subprocess, "run", side_effect=results) as run, \
                mock.patch("sys.stdout"), mock.patch("sys.stderr"):
            with self.assertRaisesRegex(adguard.CliError, "failed on pihome$"):
                adguard.run(config, adguard.parse_args(["pause", "15m"]))
        self.assertEqual([c.args[0][4] for c in run.call_args_list], ["pihome", "bigtasty"])
        for c in run.call_args_list:
            self.assertEqual(shlex.split(c.args[0][-1]), ["sudo", "-n", "/run/current-system/sw/bin/adguard", "pause", "15m"])
        with mock.patch.object(adguard.subprocess, "run", return_value=mock.Mock(returncode=0)), mock.patch("sys.stdout"):
            adguard.run(config, ("resume", []))
        for bad in ([], ["pihome", "bad host"], "pihome"):
            with self.assertRaisesRegex(adguard.CliError, "invalid remote configuration"):
                adguard.run(dict(config, targets=bad), ("status", []))


if __name__ == "__main__":
    unittest.main()
