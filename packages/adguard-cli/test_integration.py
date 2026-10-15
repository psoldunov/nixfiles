"""Offline integration coverage against the packaged AdGuard Home and Unbound."""
import json
import os
import socket
import subprocess
import tempfile
import time
import unittest
from unittest import mock

import adguard


PASSWORD = "integration-password"
# Public test-only bcrypt hash for PASSWORD; deliberately low cost for sandbox speed.
PASSWORD_HASH = "$2b$04$.uLzHSqW7m89OF0LtZh3qO/Ho5Rj203Tjs3RWz4wVgLSQ8CHmNbw6"


def free_port():
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return sock.getsockname()[1]


def dns_query(port, name):
    labels = name.rstrip(".").split(".")
    question = b"".join(bytes([len(label)]) + label.encode("ascii") for label in labels) + b"\0\0\x01\0\x01"
    packet = b"\x51\x7a\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00" + question
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.settimeout(2)
        sock.sendto(packet, ("127.0.0.1", port))
        response, _ = sock.recvfrom(4096)
    if response[:2] != packet[:2]:
        raise AssertionError("DNS response transaction id mismatch")
    answers = []
    offset = 12
    while response[offset]:
        offset += response[offset] + 1
    offset += 5  # root label plus QTYPE/QCLASS
    for _ in range(int.from_bytes(response[6:8], "big")):
        if response[offset] & 0xC0 == 0xC0:
            offset += 2
        else:
            while response[offset]:
                offset += response[offset] + 1
            offset += 1
        rtype = int.from_bytes(response[offset:offset + 2], "big")
        rdlength = int.from_bytes(response[offset + 8:offset + 10], "big")
        rdata = response[offset + 10:offset + 10 + rdlength]
        if rtype == 1 and len(rdata) == 4:
            answers.append(socket.inet_ntoa(rdata))
        offset += 10 + rdlength
    return int.from_bytes(response[2:4], "big") & 0xF, answers


@unittest.skipUnless(os.environ.get("ADGUARDHOME_BIN") and os.environ.get("UNBOUND_BIN") and os.environ.get("AGH_BASE_CONFIG"),
                     "native daemon paths are set by the Nix check")
class NativeIntegrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory(prefix="adguard-integration-")
        cls.work = cls.tmp.name
        cls.agh_port, cls.dns_port, cls.upstream_port = free_port(), free_port(), free_port()
        cls.control_socket = os.path.join(cls.work, "unbound.ctl")
        cls.unbound_conf = os.path.join(cls.work, "unbound.conf")
        cls.control_conf = os.path.join(cls.work, "unbound-control.conf")
        cls.agh_conf = os.path.join(cls.work, "AdGuardHome.json")
        cls.agh_work = os.path.join(cls.work, "agh-work")
        os.mkdir(cls.agh_work)

        with open(cls.unbound_conf, "w", encoding="utf-8") as stream:
            stream.write(f'''server:
  directory: "{cls.work}"
  username: "nixbld"
  chroot: ""
  interface: 127.0.0.1
  port: {cls.upstream_port}
  do-ip4: yes
  do-ip6: no
  do-udp: yes
  do-tcp: yes
  access-control: 127.0.0.0/8 allow
  local-zone: test. static
  local-data: "example.test. 60 IN A 192.0.2.20"
  local-data: "blocked.example.test. 60 IN A 192.0.2.123"
remote-control:
  control-enable: yes
  control-interface: {cls.control_socket}
  control-use-cert: no
''')
        # This is intentionally the same remote-control client configuration used by PiHome.
        with open(cls.control_conf, "w", encoding="utf-8") as stream:
            stream.write(f'''remote-control:
  control-enable: yes
  control-interface: {cls.control_socket}
  control-use-cert: no
''')

        with open(os.environ["AGH_BASE_CONFIG"], encoding="utf-8") as stream:
            config = json.load(stream)
        config["schema_version"] = 34
        config["http"]["address"] = f"127.0.0.1:{cls.agh_port}"
        config["users"] = [{"name": "integration", "password": PASSWORD_HASH}]
        config["dns"].update({"bind_hosts": ["127.0.0.1"], "port": cls.dns_port,
                              "upstream_dns": [f"127.0.0.1:{cls.upstream_port}"],
                              "bootstrap_dns": [], "fallback_dns": []})
        config["filtering"].update({"filters": [], "filtering_enabled": True,
                                    "protection_enabled": True, "protection_disabled_until": None,
                                    "rewrites": []})
        config["filters"] = []
        config["user_rules"] = ["||blocked.example.test^"]
        config["querylog"]["enabled"] = False
        config["statistics"]["enabled"] = False
        with open(cls.agh_conf, "w", encoding="utf-8") as stream:
            json.dump(config, stream)

        cls.credentials = os.path.join(cls.work, "credentials.json")
        with open(cls.credentials, "w", encoding="utf-8") as stream:
            json.dump({"username": "integration", "password": PASSWORD}, stream)
        os.chmod(cls.credentials, 0o600)

        unbound = os.path.join(os.environ["UNBOUND_BIN"], "bin", "unbound")
        control = os.path.join(os.environ["UNBOUND_BIN"], "bin", "unbound-control")
        cls.control_command = [control, "-c", cls.control_conf, "flush_zone", "."]
        cls.unbound = subprocess.Popen([unbound, "-d", "-c", cls.unbound_conf],
                                       stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
        try:
            cls.wait_for(lambda: os.path.exists(cls.control_socket), "Unbound control socket")
            result = subprocess.run([control, "-c", cls.control_conf, "status"], capture_output=True, timeout=3)
            if result.returncode:
                raise RuntimeError("unbound-control status failed: " + result.stderr.decode(errors="replace"))

            agh = os.path.join(os.environ["ADGUARDHOME_BIN"], "bin", "AdGuardHome")
            check = subprocess.run([agh, "-c", cls.agh_conf, "-w", cls.agh_work, "--check-config"],
                                   capture_output=True, timeout=5)
            if check.returncode:
                raise RuntimeError("AdGuard config rejected: " + check.stderr.decode(errors="replace"))
            cls.agh = subprocess.Popen([agh, "-c", cls.agh_conf, "-w", cls.agh_work,
                                        "--no-check-update", "--no-etc-hosts"],
                                       stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
            cls.wait_for(cls.api_ready, "AdGuard API")
            cls.wait_for(lambda: cls.dns_ready(), "AdGuard DNS listener")
        except Exception:
            cls.tearDownClass()
            raise

    @classmethod
    def wait_for(cls, predicate, description):
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            if cls.unbound.poll() is not None:
                detail = cls.unbound.stderr.read().decode(errors="replace")
                raise RuntimeError("Unbound exited during startup: " + detail)
            if getattr(cls, "agh", None) and cls.agh.poll() is not None:
                detail = cls.agh.stderr.read().decode(errors="replace")
                raise RuntimeError("AdGuard exited during startup: " + detail)
            if predicate():
                return
            time.sleep(0.1)
        raise TimeoutError(f"timed out waiting for {description}")

    @classmethod
    def api_ready(cls):
        try:
            with socket.create_connection(("127.0.0.1", cls.agh_port), timeout=0.2):
                return True
        except OSError:
            return False

    @classmethod
    def dns_ready(cls):
        try:
            dns_query(cls.dns_port, "example.test")
            return True
        except (OSError, IndexError):
            return False

    @classmethod
    def tearDownClass(cls):
        for name in ("agh", "unbound"):
            process = getattr(cls, name, None)
            if process and process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait(timeout=2)
            if process and process.stderr:
                process.stderr.close()
        tmp = getattr(cls, "tmp", None)
        if tmp:
            tmp.cleanup()

    def command(self, *args, password=PASSWORD):
        config = {"mode": "local", "base_url": f"http://127.0.0.1:{self.agh_port}",
                  "credentials_file": self.credentials, "unbound_control": self.control_command}
        # The synthetic fixture file is intentionally non-root-owned in the build sandbox.
        # Keep production ownership validation intact and scope the mock to this credential.
        real_stat = os.stat
        def scoped_stat(path, *stat_args, **stat_kwargs):
            if path == self.credentials:
                return type("FixtureStat", (), {"st_uid": 0, "st_mode": 0o100600})()
            return real_stat(path, *stat_args, **stat_kwargs)
        with mock.patch.object(adguard.os, "stat", side_effect=scoped_stat):
            return adguard.run(config, adguard.parse_args(list(args)))

    def api(self, method, path, payload=None, password=PASSWORD):
        import base64
        import urllib.error
        import urllib.request
        body = json.dumps(payload).encode() if payload is not None else None
        token = base64.b64encode(f"integration:{password}".encode()).decode()
        request = urllib.request.Request(f"http://127.0.0.1:{self.agh_port}{path}", data=body,
                                         method=method, headers={"Authorization": "Basic " + token,
                                                                 "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(request, timeout=3) as response:
                return response.status, response.read()
        except urllib.error.HTTPError as error:
            return error.code, error.read()

    def test_api_auth_status_pause_resume_dns_and_flush(self):
        status, body = self.api("GET", "/control/status")
        self.assertEqual(status, 200)
        self.assertIsInstance(json.loads(body), dict)
        self.assertEqual(self.api("GET", "/control/status", password="wrongpassword")[0], 401)

        with mock.patch("builtins.print"):
            self.command("status")
        self.assertEqual(dns_query(self.dns_port, "blocked.example.test")[1], ["0.0.0.0"])
        self.assertEqual(dns_query(self.dns_port, "example.test")[1], ["192.0.2.20"])

        with mock.patch("builtins.print"):
            self.command("pause", "30s")
        status, body = self.api("GET", "/control/status")
        self.assertEqual(status, 200)
        self.assertFalse(json.loads(body)["protection_enabled"])
        self.assertEqual(dns_query(self.dns_port, "blocked.example.test")[1], ["192.0.2.123"])
        self.assertEqual(dns_query(self.dns_port, "example.test")[1], ["192.0.2.20"])

        with mock.patch("builtins.print"):
            self.command("resume")
        self.assertTrue(json.loads(self.api("GET", "/control/status")[1])["protection_enabled"])
        self.assertEqual(dns_query(self.dns_port, "blocked.example.test")[1], ["0.0.0.0"])

        # Verify the actual Unix-socket command first, then the CLI's ordered two-cache flush.
        subprocess.run(self.control_command, check=True, capture_output=True, timeout=3)
        with mock.patch("builtins.print"):
            self.command("flush")


if __name__ == "__main__":
    unittest.main()
