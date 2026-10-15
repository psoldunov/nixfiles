#!/usr/bin/env python3
"""Small, dependency-free AdGuard Home and Unbound operator CLI."""
import base64
import datetime
import json
import os
import re
import subprocess
import shlex
import sys
import urllib.error
import urllib.parse
import urllib.request

TIMEOUT = 5
MAX_RESPONSE = 65536
MAX_PAUSE_MS = 7 * 24 * 60 * 60 * 1000


class CliError(Exception):
    pass


def parse_args(args):
    if not args or args[0] in ("-h", "--help", "help"):
        return ("help", [])
    cmd = args[0]
    if cmd in ("status", "resume", "flush") and len(args) == 1:
        return cmd, []
    if cmd == "pause" and len(args) <= 2:
        token = args[1] if len(args) == 2 else "5m"
        match = re.fullmatch(r"([0-9]+)([smh])", token)
        if not match:
            raise CliError("pause duration must be a positive integer followed by s, m, or h")
        n = int(match.group(1))
        multiplier = {"s": 1000, "m": 60000, "h": 3600000}[match.group(2)]
        millis = n * multiplier
        if n <= 0 or millis > MAX_PAUSE_MS:
            raise CliError("pause duration must be positive and no longer than 7 days")
        return cmd, [token]
    if cmd in ("status", "resume", "flush", "pause"):
        raise CliError("unexpected or invalid arguments")
    raise CliError("unknown command")


def help_text():
    return "Usage: adguard {status|pause [duration]|resume|flush}\nPause duration: positive integer with s, m, or h suffix (default 5m; maximum 7d).\n"


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def request(config, method, path, payload=None):
    base = config["base_url"]
    parsed = urllib.parse.urlsplit(base)
    if parsed.scheme != "http" or parsed.hostname not in ("127.0.0.1", "::1", "localhost") or parsed.username or parsed.password:
        raise CliError("local base URL must be loopback HTTP")
    credentials_path = config["credentials_file"]
    try:
        st = os.stat(credentials_path)
        if st.st_uid != 0 or st.st_mode & 0o077:
            raise CliError("credentials file must be root-owned and not accessible to group or others")
        with open(credentials_path, encoding="utf-8") as stream:
            credentials = json.load(stream)
        user, password = credentials["username"], credentials["password"]
        if not isinstance(user, str) or not isinstance(password, str):
            raise ValueError()
    except CliError:
        raise
    except Exception:
        raise CliError("cannot read valid AdGuard credentials")
    token = base64.b64encode((user + ":" + password).encode()).decode("ascii")
    body = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(base.rstrip("/") + path, data=body, method=method,
                                 headers={"Authorization": "Basic " + token,
                                          "Content-Type": "application/json"})
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), NoRedirect())
    try:
        with opener.open(req, timeout=TIMEOUT) as response:
            data = response.read(MAX_RESPONSE + 1)
    except urllib.error.HTTPError as e:
        raise CliError("AdGuard HTTP error: status %d" % e.code)
    except Exception as e:
        if isinstance(e, TimeoutError) or (isinstance(e, urllib.error.URLError) and isinstance(e.reason, TimeoutError)):
            raise CliError("AdGuard request timed out")
        raise CliError("AdGuard transport failure")
    if len(data) > MAX_RESPONSE:
        raise CliError("AdGuard response exceeded size limit")
    if not data:
        return None
    try:
        return json.loads(data.decode("utf-8"))
    except Exception:
        if method == "GET" and path == "/control/status":
            raise CliError("AdGuard returned malformed status JSON")
        return None


def run(config, command):
    if config.get("mode", "local") == "remote":
        ssh = config.get("ssh")
        target = config.get("target")
        if not isinstance(ssh, str) or not os.path.isabs(ssh) or not isinstance(target, str) or not re.fullmatch(r"[A-Za-z0-9_.@-]+", target):
            raise CliError("invalid remote configuration")
        remote = ["sudo", "-n", "/run/current-system/sw/bin/adguard", command[0]] + command[1]
        try:
            result = subprocess.run([ssh, "-oBatchMode=yes", "-oConnectTimeout=5", "--", target, shlex.join(remote)],
                                    timeout=30, check=False)
        except subprocess.TimeoutExpired:
            raise CliError("remote AdGuard command timed out")
        except Exception:
            raise CliError("SSH transport failure")
        if result.returncode:
            raise CliError("remote AdGuard command failed")
        return
    if config.get("mode", "local") != "local":
        raise CliError("invalid mode")
    if command[0] == "flush":
        control = config.get("unbound_control")
        if not isinstance(control, list) or not control or not all(isinstance(x, str) for x in control):
            raise CliError("invalid Unbound control configuration")
        try:
            result = subprocess.run(control, timeout=TIMEOUT, check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception:
            raise CliError("Unbound control failed")
        if result.returncode:
            raise CliError("Unbound cache flush failed; AdGuard cache was not cleared")
        try:
            request(config, "POST", "/control/cache_clear", {})
        except CliError as e:
            raise CliError("Unbound cache flushed, but AdGuard cache clear failed: " + str(e))
        print("Unbound and AdGuard caches flushed")
    elif command[0] == "pause":
        match = re.fullmatch(r"([0-9]+)([smh])", command[1][0])
        duration = int(match.group(1)) * {"s": 1000, "m": 60000, "h": 3600000}[match.group(2)]
        request(config, "POST", "/control/protection", {"enabled": False, "duration": duration})
        print("AdGuard protection paused")
    elif command[0] == "resume":
        request(config, "POST", "/control/protection", {"enabled": True})
        print("AdGuard protection enabled")
    else:
        data = request(config, "GET", "/control/status")
        if not isinstance(data, dict):
            raise CliError("AdGuard status response is not a JSON object")
        until = data.get("protection_disabled_until")
        disabled_until = False
        if isinstance(until, str) and until:
            try:
                expires = datetime.datetime.fromisoformat(until.replace("Z", "+00:00"))
                if expires.tzinfo is None:
                    expires = expires.replace(tzinfo=datetime.timezone.utc)
                disabled_until = expires > datetime.datetime.now(datetime.timezone.utc)
            except ValueError:
                disabled_until = True
        if "protection_enabled" in data:
            if not data["protection_enabled"] or disabled_until:
                print("Protection: paused" + (" until " + str(until) if until else ""))
            else:
                print("Protection: enabled")
        print(json.dumps(data, sort_keys=True))


def main():
    if len(sys.argv) < 2:
        print(help_text(), end="")
        return 0
    try:
        command = parse_args(sys.argv[2:])
        if command[0] == "help":
            print(help_text(), end="")
            return 0
        config = json.loads(sys.argv[1])
        run(config, command)
        return 0
    except CliError as e:
        print("adguard: " + str(e), file=sys.stderr)
        return 1
    except Exception:
        print("adguard: operation failed", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
