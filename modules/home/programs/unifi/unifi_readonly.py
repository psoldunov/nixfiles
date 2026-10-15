"""Narrow, read-only client for the UniFi Network Integration API."""

from __future__ import annotations

import argparse
import contextlib
import hashlib
import http.client
import importlib
import json
import os
import re
import ssl
import stat
import sys
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, cast

BASE_URL = "https://10.24.24.1/proxy/network/integration/v1"
MAX_BODY_BYTES = 4 * 1024 * 1024
TIMEOUT_SECONDS = 15
# Independently confirmed by the controller owner, not trusted from discovery.
PINNED_CERTIFICATE_SHA256 = "4166cadda1eb0d6dd7b9b3f46c21a120150659869cb5e77befb37d805177d521"
PINNED_SERVER_NAME = "unifi.local"
UUID_RE = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
    re.IGNORECASE,
)
SENSITIVE_KEYS = {
    "password",
    "passphrase",
    "presharedkey",
    "presharedkeys",
    "psk",
    "token",
    "tokens",
    "secret",
    "secrets",
    "privatekey",
    "apikey",
    "authorization",
}


class UniFiError(RuntimeError):
    """A safe error suitable for a CLI or MCP response."""


def _normalise_key(value: str) -> str:
    return re.sub(r"[^a-z0-9]", "", value.lower())


def redact(value: Any, api_key: str | None = None) -> Any:
    """Recursively remove sensitive response fields and accidental key echoes."""
    if isinstance(value, dict):
        return {
            redact(str(key), api_key): "[REDACTED]"
            if _normalise_key(str(key)).endswith(tuple(SENSITIVE_KEYS)) else redact(item, api_key)
            for key, item in value.items()
        }
    if isinstance(value, list):
        return [redact(item, api_key) for item in value]
    if isinstance(value, str) and api_key:
        return value.replace(api_key, "[REDACTED]")
    return value


def _read_api_key(path: str | None) -> str:
    if not path:
        raise UniFiError("UNIFI_API_KEY_FILE is not configured")
    try:
        file_stat = os.stat(path)
        if not stat.S_ISREG(file_stat.st_mode) or file_stat.st_mode & 0o077:
            raise UniFiError("API key file permissions are too broad")
        with open(path, encoding="utf-8") as key_file:
            key = key_file.read(16385)
    except (OSError, UnicodeError):
        raise UniFiError("API key file is unavailable or has invalid encoding") from None
    if len(key) > 16384:
        raise UniFiError("API key file is too large")
    if key.endswith("\n"):
        key = key[:-1]
    if not key or "\n" in key or "\r" in key or any(ord(char) < 33 or ord(char) > 126 for char in key):
        raise UniFiError("API key file has an invalid value")
    return key


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req: Any, fp: Any, code: int, msg: str, headers: Any, newurl: str) -> None:
        return None


class _PinnedOpener:
    """Verified TLS plus an exact legacy leaf pin, checked before HTTP bytes."""

    def __init__(self, certificate_file: str) -> None:
        # Keep the default transport usable with the standard library alone.
        import urllib3
        from urllib3.connection import HTTPSConnection
        from urllib3.connectionpool import HTTPSConnectionPool
        from urllib3.util.ssl_ import assert_fingerprint

        try:
            with open(certificate_file, encoding="ascii") as certificate:
                pem = certificate.read(65537)
            if len(pem) > 65536 or not re.fullmatch(
                r"\s*-----BEGIN CERTIFICATE-----\s+[A-Za-z0-9+/=\s]+-----END CERTIFICATE-----\s*", pem
            ):
                raise ValueError("invalid certificate PEM")
            der = ssl.PEM_cert_to_DER_cert(pem)
            if hashlib.sha256(der).hexdigest() != PINNED_CERTIFICATE_SHA256:
                raise ValueError("certificate pin mismatch")
            # Use the verified bytes, not a second file read susceptible to replacement.
            context = ssl.create_default_context(cadata=pem)
            # Owner-approved compatibility for this exact legacy UDM leaf only:
            # it omits Basic Constraints. Retain CERT_REQUIRED, native hostname,
            # signature/expiry verification, and every other verification flag.
            context.verify_flags &= ~ssl.VERIFY_X509_STRICT
        except (OSError, ValueError, UnicodeError):
            raise UniFiError("cannot initialize pinned TLS; check the confirmed public certificate") from None

        class PinnedConnection(HTTPSConnection):
            def connect(self) -> None:
                try:
                    # urllib3's built-in assert_fingerprint disables hostname checking.
                    # Leave both asserts unset so its normal TLS handshake checks the
                    # CA, expiry and server_hostname with check_hostname still True.
                    super().connect()
                    assert self.sock is not None
                    assert_fingerprint(cast(ssl.SSLSocket, self.sock).getpeercert(binary_form=True), PINNED_CERTIFICATE_SHA256)
                except BaseException:
                    self.close()
                    raise

        class PinnedPool(HTTPSConnectionPool):
            ConnectionCls: Any = PinnedConnection

        self.pool = urllib3.PoolManager(
            ssl_context=context, cert_reqs=ssl.CERT_REQUIRED,
            server_hostname=PINNED_SERVER_NAME, retries=False,
        )
        # Instance-local mapping: never change urllib3's global pool classes.
        self.pool.pool_classes_by_scheme = {"https": PinnedPool}
        self.http_error = urllib3.exceptions.HTTPError

    @contextlib.contextmanager
    def open(self, request: Any, timeout: int) -> Any:
        response = None
        try:
            response = self.pool.request(
                "GET", request.full_url, headers=dict(request.header_items()),
                timeout=timeout, retries=False, redirect=False, preload_content=False,
            )
            if 300 <= response.status < 400:
                raise UniFiError("controller redirect refused")
            yield response
        except self.http_error:
            raise UniFiError("controller connection failed; check LAN/VPN access and TLS trust") from None
        finally:
            if response is not None:
                response.close()
                response.release_conn()
            self.pool.clear()


class UniFiClient:
    """Only exposes the eight approved GET endpoints."""

    def __init__(self, *, key_file: str | None = None, ca_file: str | None = None,
                 pinned_certificate: str | None = None, opener: Any = None) -> None:
        self.key_file = key_file if key_file is not None else os.environ.get("UNIFI_API_KEY_FILE")
        self.ca_file = ca_file if ca_file is not None else os.environ.get("UNIFI_CA_FILE")
        certificate = pinned_certificate if pinned_certificate is not None else os.environ.get("UNIFI_PINNED_CERTIFICATE")
        if opener is None and certificate is not None:
            opener = _PinnedOpener(certificate)
        if opener is None:
            try:
                context = ssl.create_default_context(cafile=self.ca_file)
            except (OSError, ValueError):
                raise UniFiError("cannot initialize TLS; check the configured CA bundle") from None
            opener = urllib.request.build_opener(
                urllib.request.ProxyHandler({}), _NoRedirect(), urllib.request.HTTPSHandler(context=context)
            )
        self.opener = opener

    @staticmethod
    def _uuid(value: str, label: str) -> str:
        if not isinstance(value, str) or not UUID_RE.fullmatch(value):
            raise UniFiError(f"{label} must be a UUID")
        return value

    @staticmethod
    def _pagination(offset: int = 0, limit: int = 50) -> str:
        if isinstance(offset, bool) or not isinstance(offset, int) or offset < 0:
            raise UniFiError("offset must be a non-negative integer")
        if isinstance(limit, bool) or not isinstance(limit, int) or not 1 <= limit <= 100:
            raise UniFiError("limit must be between 1 and 100")
        return urllib.parse.urlencode({"offset": offset, "limit": limit})

    def _get(self, path: str, query: str | None = None) -> Any:
        key = _read_api_key(self.key_file)
        url = f"{BASE_URL}{path}" + (f"?{query}" if query else "")
        # The base is a fixed HTTPS literal and paths come only from the eight methods below.
        request = urllib.request.Request(url, headers={"X-API-KEY": key, "Accept": "application/json"}, method="GET")  # nosec B310
        try:
            with self.opener.open(request, timeout=TIMEOUT_SECONDS) as response:
                status = getattr(response, "status", None)
                if status is None:
                    status = response.getcode()
                if status < 200 or status >= 300:
                    raise UniFiError("controller returned an unsuccessful response")
                payload = response.read(MAX_BODY_BYTES + 1)
        except urllib.error.HTTPError as exc:
            if 300 <= exc.code < 400:
                raise UniFiError("controller redirect refused") from None
            raise UniFiError(f"controller request failed (HTTP {exc.code})") from None
        except (urllib.error.URLError, TimeoutError, OSError, http.client.HTTPException):
            raise UniFiError("controller connection failed; check LAN/VPN access and TLS trust") from None
        if len(payload) > MAX_BODY_BYTES:
            raise UniFiError("controller response is too large")
        try:
            return redact(json.loads(payload.decode("utf-8")), key)
        except (UnicodeError, ValueError, RecursionError):
            raise UniFiError("controller returned invalid JSON") from None

    def info(self) -> Any:
        return self._get("/info")

    def sites(self, offset: int = 0, limit: int = 50) -> Any:
        return self._get("/sites", self._pagination(offset, limit))

    def list_devices(self, site_id: str, offset: int = 0, limit: int = 50) -> Any:
        return self._get(f"/sites/{self._uuid(site_id, 'site_id')}/devices", self._pagination(offset, limit))

    def get_device(self, site_id: str, device_id: str) -> Any:
        return self._get(f"/sites/{self._uuid(site_id, 'site_id')}/devices/{self._uuid(device_id, 'device_id')}")

    def device_latest_statistics(self, site_id: str, device_id: str) -> Any:
        return self._get(f"/sites/{self._uuid(site_id, 'site_id')}/devices/{self._uuid(device_id, 'device_id')}/statistics/latest")

    def list_clients(self, site_id: str, offset: int = 0, limit: int = 50) -> Any:
        return self._get(f"/sites/{self._uuid(site_id, 'site_id')}/clients", self._pagination(offset, limit))

    def get_client(self, site_id: str, client_id: str) -> Any:
        return self._get(f"/sites/{self._uuid(site_id, 'site_id')}/clients/{self._uuid(client_id, 'client_id')}")

    def list_networks(self, site_id: str, offset: int = 0, limit: int = 50) -> Any:
        return self._get(f"/sites/{self._uuid(site_id, 'site_id')}/networks", self._pagination(offset, limit))


def _add_pagination(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--offset", type=int, default=0)
    parser.add_argument("--limit", type=int, default=50)


def cli(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Read-only UniFi Network Integration API client")
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("mcp", help="start the read-only stdio MCP server")
    subparsers.add_parser("info", help="get controller information")
    sites = subparsers.add_parser("sites", help="list sites")
    _add_pagination(sites)
    devices = subparsers.add_parser("devices", help="list devices for a site")
    devices.add_argument("site_id")
    _add_pagination(devices)
    device = subparsers.add_parser("device", help="get a device")
    device.add_argument("site_id")
    device.add_argument("device_id")
    statistics = subparsers.add_parser("device-latest-statistics", help="get latest device statistics")
    statistics.add_argument("site_id")
    statistics.add_argument("device_id")
    clients = subparsers.add_parser("clients", help="list clients for a site")
    clients.add_argument("site_id")
    _add_pagination(clients)
    client = subparsers.add_parser("client", help="get a client")
    client.add_argument("site_id")
    client.add_argument("client_id")
    networks = subparsers.add_parser("networks", help="list networks for a site")
    networks.add_argument("site_id")
    _add_pagination(networks)
    args = parser.parse_args(argv)
    try:
        if args.command == "mcp":
            make_mcp().run(transport="stdio")
            return 0
        client_api = UniFiClient()
        calls = {
            "info": lambda: client_api.info(),
            "sites": lambda: client_api.sites(args.offset, args.limit),
            "devices": lambda: client_api.list_devices(args.site_id, args.offset, args.limit),
            "device": lambda: client_api.get_device(args.site_id, args.device_id),
            "device-latest-statistics": lambda: client_api.device_latest_statistics(args.site_id, args.device_id),
            "clients": lambda: client_api.list_clients(args.site_id, args.offset, args.limit),
            "client": lambda: client_api.get_client(args.site_id, args.client_id),
            "networks": lambda: client_api.list_networks(args.site_id, args.offset, args.limit),
        }
        print(json.dumps(calls[args.command](), indent=2, sort_keys=True))
        return 0
    except UniFiError as exc:
        print(f"unifi-readonly: {exc}", file=sys.stderr)
        return 2


def make_mcp() -> Any:
    """Create the stdio MCP server; the SDK is intentionally imported lazily."""
    # The SDK is supplied by the Nix wrapper, not required by the offline CLI tests.
    fastmcp = importlib.import_module("mcp.server.fastmcp")

    mcp = fastmcp.FastMCP("unifi-readonly")

    @mcp.tool()
    def info() -> Any:
        """Get controller information."""
        return UniFiClient().info()

    @mcp.tool()
    def sites(offset: int = 0, limit: int = 50) -> Any:
        """List sites with bounded pagination."""
        return UniFiClient().sites(offset, limit)

    @mcp.tool()
    def list_devices(site_id: str, offset: int = 0, limit: int = 50) -> Any:
        """List devices in one site with bounded pagination."""
        return UniFiClient().list_devices(site_id, offset, limit)

    @mcp.tool()
    def get_device(site_id: str, device_id: str) -> Any:
        """Get one device."""
        return UniFiClient().get_device(site_id, device_id)

    @mcp.tool()
    def device_latest_statistics(site_id: str, device_id: str) -> Any:
        """Get latest statistics for one device."""
        return UniFiClient().device_latest_statistics(site_id, device_id)

    @mcp.tool()
    def list_clients(site_id: str, offset: int = 0, limit: int = 50) -> Any:
        """List clients in one site with bounded pagination."""
        return UniFiClient().list_clients(site_id, offset, limit)

    @mcp.tool()
    def get_client(site_id: str, client_id: str) -> Any:
        """Get one client."""
        return UniFiClient().get_client(site_id, client_id)

    @mcp.tool()
    def list_networks(site_id: str, offset: int = 0, limit: int = 50) -> Any:
        """List networks in one site with bounded pagination."""
        return UniFiClient().list_networks(site_id, offset, limit)

    return mcp


def main() -> int:
    return cli()


if __name__ == "__main__":
    raise SystemExit(main())
