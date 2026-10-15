import asyncio
import contextlib
import importlib.util
import io
import json
import os
import tempfile
import traceback
import unittest
from pathlib import Path
from unittest.mock import patch
import urllib.error

MODULE = Path(__file__).parents[1] / "unifi_readonly.py"
spec = importlib.util.spec_from_file_location("unifi_readonly", MODULE)
unifi = importlib.util.module_from_spec(spec)
assert spec.loader
spec.loader.exec_module(unifi)

SITE = "123e4567-e89b-42d3-a456-426614174000"
DEVICE = "123e4567-e89b-42d3-a456-426614174001"
CLIENT = "123e4567-e89b-42d3-a456-426614174002"


class Response:
    status = 200

    def __init__(self, payload=b'{"ok": true}'):
        self.payload = payload

    def __enter__(self):
        return self

    def __exit__(self, *_):
        return False

    def read(self, _: int) -> bytes:
        return self.payload


class Opener:
    def __init__(self, response=None, error=None):
        self.response = response or Response()
        self.error = error
        self.requests = []

    def open(self, request, timeout):
        self.requests.append((request, timeout))
        if self.error:
            raise self.error
        return self.response


class UniFiClientTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.key_path = Path(self.tempdir.name) / "key"
        self.key_path.write_text("test-api-key\n")
        self.key_path.chmod(0o600)
        self.opener = Opener()
        self.client = unifi.UniFiClient(key_file=str(self.key_path), opener=self.opener)

    def tearDown(self):
        self.tempdir.cleanup()

    def test_eight_routes_are_get_only(self):
        results = [
            self.client.info(),
            self.client.sites(),
            self.client.list_devices(SITE),
            self.client.get_device(SITE, DEVICE),
            self.client.device_latest_statistics(SITE, DEVICE),
            self.client.list_clients(SITE),
            self.client.get_client(SITE, CLIENT),
            self.client.list_networks(SITE),
        ]
        self.assertEqual([result["ok"] for result in results], [True] * 8)
        self.assertEqual(
            [request.full_url for request, _ in self.opener.requests],
            [
                f"{unifi.BASE_URL}/info",
                f"{unifi.BASE_URL}/sites?offset=0&limit=50",
                f"{unifi.BASE_URL}/sites/{SITE}/devices?offset=0&limit=50",
                f"{unifi.BASE_URL}/sites/{SITE}/devices/{DEVICE}",
                f"{unifi.BASE_URL}/sites/{SITE}/devices/{DEVICE}/statistics/latest",
                f"{unifi.BASE_URL}/sites/{SITE}/clients?offset=0&limit=50",
                f"{unifi.BASE_URL}/sites/{SITE}/clients/{CLIENT}",
                f"{unifi.BASE_URL}/sites/{SITE}/networks?offset=0&limit=50",
            ],
        )
        for request, timeout in self.opener.requests:
            self.assertEqual(request.get_method(), "GET")
            self.assertEqual(request.get_header("X-api-key"), "test-api-key")
            self.assertEqual(timeout, unifi.TIMEOUT_SECONDS)

    def test_pagination_and_injection_are_rejected_before_http(self):
        for call in (
            lambda: self.client.sites(-1),
            lambda: self.client.sites(0, 101),
            lambda: self.client.list_devices("../../info"),
            lambda: self.client.get_client(SITE, DEVICE + "/x"),
        ):
            with self.assertRaises(unifi.UniFiError):
                call()
        self.assertEqual(self.opener.requests, [])

    def test_missing_empty_unsafe_and_open_key_files_fail(self):
        for content, mode in (("", 0o600), ("bad\nvalue", 0o600), ("key\n\n", 0o600), ("key", 0o644)):
            path = Path(self.tempdir.name) / f"key-{mode}-{len(content)}"
            path.write_text(content)
            path.chmod(mode)
            with self.assertRaises(unifi.UniFiError):
                unifi.UniFiClient(key_file=str(path), opener=self.opener).info()
        with patch.dict(os.environ, {}, clear=True), self.assertRaises(unifi.UniFiError):
            unifi.UniFiClient(key_file=None, opener=self.opener).info()
        self.assertEqual(self.opener.requests, [])

    def test_response_failures_are_sanitized(self):
        unsuccessful = Response()
        unsuccessful.status = 503
        cases = [
            Opener(error=TimeoutError("api key test-api-key leaked")),
            Opener(error=urllib.error.URLError("api key test-api-key leaked")),
            Opener(response=unsuccessful),
            Opener(error=urllib.error.HTTPError("https://elsewhere", 500, "key test-api-key", {}, None)),
            Opener(response=Response(b"not-json")),
            Opener(response=Response(b"x" * (unifi.MAX_BODY_BYTES + 1))),
        ]
        for opener in cases:
            try:
                unifi.UniFiClient(key_file=str(self.key_path), opener=opener).info()
            except unifi.UniFiError:
                self.assertNotIn("test-api-key", traceback.format_exc())
            else:
                self.fail("unsafe response was accepted")

    def test_redirects_are_refused(self):
        opener = Opener(error=urllib.error.HTTPError("https://other", 302, "redirect", {}, None))
        with self.assertRaisesRegex(unifi.UniFiError, "redirect refused"):
            unifi.UniFiClient(key_file=str(self.key_path), opener=opener).info()

    def test_redaction_handles_nested_lists_keys_and_strings(self):
        payload = {
            "api_key": "test-api-key", "nested": [{"pre_shared_key": "x"}],
            "text": "key=test-api-key", "test-api-key": "echoed as a key",
            "presharedKeys": [{"password": "wifi-secret"}],
            "accessToken": "access-secret", "refresh_token": "refresh-secret",
            "wifiPassword": "another-secret", "name": "visible device",
        }
        opener = Opener(response=Response(json.dumps(payload).encode()))
        result = unifi.UniFiClient(key_file=str(self.key_path), opener=opener).info()
        self.assertEqual(result["api_key"], "[REDACTED]")
        self.assertEqual(result["nested"][0]["pre_shared_key"], "[REDACTED]")
        self.assertEqual(result["text"], "key=[REDACTED]")
        self.assertEqual(result["[REDACTED]"], "[REDACTED]")
        self.assertEqual(result["name"], "visible device")
        for name in ("presharedKeys", "accessToken", "refresh_token", "wifiPassword"):
            self.assertEqual(result[name], "[REDACTED]")
        self.assertNotIn("test-api-key", json.dumps(result))

    def test_default_transport_is_strict_tls_with_optional_ca_and_no_proxy(self):
        sentinel_context = object()
        with patch.object(unifi.ssl, "create_default_context", return_value=sentinel_context) as context, patch.object(
            unifi.urllib.request, "build_opener", return_value=Opener()
        ) as build:
            unifi.UniFiClient(key_file=str(self.key_path), ca_file="/tmp/ca.pem")
        context.assert_called_once_with(cafile="/tmp/ca.pem")
        handlers = build.call_args.args
        self.assertIsInstance(handlers[0], unifi.urllib.request.ProxyHandler)
        self.assertEqual(handlers[0].proxies, {})
        self.assertIsInstance(handlers[1], unifi._NoRedirect)
        self.assertIsInstance(handlers[2], unifi.urllib.request.HTTPSHandler)

    def test_cli_invalid_id_does_not_make_network_request(self):
        with patch.object(unifi, "UniFiClient", return_value=self.client):
            self.assertEqual(unifi.cli(["devices", "invalid"]), 2)
        self.assertEqual(self.opener.requests, [])

    def test_key_encoding_failure_has_no_raw_bytes_in_traceback(self):
        self.key_path.write_bytes(b"secret-key-contents\xff")
        try:
            self.client.info()
        except unifi.UniFiError:
            self.assertNotIn("secret-key-contents", traceback.format_exc())
        else:
            self.fail("non-UTF-8 key was accepted")
        self.assertEqual(self.opener.requests, [])

    def test_cli_ca_failure_is_a_safe_error(self):
        stderr = io.StringIO()
        with patch.object(unifi.ssl, "create_default_context", side_effect=OSError("sensitive-error")):
            with contextlib.redirect_stderr(stderr):
                self.assertEqual(unifi.cli(["info"]), 2)
        self.assertIn("cannot initialize TLS", stderr.getvalue())
        self.assertNotIn("sensitive-error", stderr.getvalue())
        self.assertNotIn("Traceback", stderr.getvalue())

    def test_uuid_versions_and_invalid_pagination(self):
        self.client.list_devices("01912345-6789-7abc-8def-0123456789ab")
        for offset, limit in ((True, 1), (0, False), (0, 0), (1.5, 2)):
            with self.assertRaises(unifi.UniFiError):
                self.client.sites(offset, limit)

    def test_redirect_handler_never_follows_new_url(self):
        handler = unifi._NoRedirect()
        self.assertIsNone(handler.redirect_request(None, None, 302, "", {}, "https://evil.example"))

    def test_cli_mcp_only_uses_stdio(self):
        with patch.object(unifi, "make_mcp") as factory:
            self.assertEqual(unifi.cli(["mcp"]), 0)
        factory.return_value.run.assert_called_once_with(transport="stdio")


@unittest.skipUnless(importlib.util.find_spec("mcp"), "MCP SDK not installed in this Python environment")
class MCPTests(unittest.TestCase):
    def test_eight_tools_and_invalid_id_without_credentials(self):
        async def check():
            from mcp.server.fastmcp.exceptions import ToolError

            server = unifi.make_mcp()
            tools = await server.list_tools()
            self.assertEqual({tool.name for tool in tools}, {
                "info", "sites", "list_devices", "get_device", "device_latest_statistics",
                "list_clients", "get_client", "list_networks",
            })
            with self.assertRaises(ToolError):
                await server.call_tool("list_devices", {"site_id": "../../unsafe"})

        with patch.dict(os.environ, {}, clear=True):
            asyncio.run(check())


if __name__ == "__main__":
    unittest.main()
