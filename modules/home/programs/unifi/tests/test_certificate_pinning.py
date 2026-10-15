"""Pin-before-HTTP regression tests; all keys and sockets here are fake."""

import hashlib
import importlib.util
import io
import os
import ssl
import tempfile
import traceback
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

from test_unifi_readonly import unifi

CERTIFICATE = Path(__file__).parents[1] / "udm-cert.pem"


@unittest.skipUnless(importlib.util.find_spec("urllib3"), "urllib3 is not installed")
class CertificatePinningTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.addCleanup(self.tempdir.cleanup)
        self.key_file = Path(self.tempdir.name) / "dummy-key"
        self.key_file.write_text("dummy-api-key")
        self.key_file.chmod(0o600)

    def client(self):
        return unifi.UniFiClient(key_file=str(self.key_file), pinned_certificate=str(CERTIFICATE))

    def test_committed_public_certificate_matches_independent_pin(self):
        der = ssl.PEM_cert_to_DER_cert(CERTIFICATE.read_text())
        self.assertEqual(hashlib.sha256(der).hexdigest(), unifi.PINNED_CERTIFICATE_SHA256)

    def test_invalid_or_replaced_certificate_fails_before_key_read(self):
        invalid = Path(self.tempdir.name) / "invalid.pem"
        for pem in ("not PEM", "-----BEGIN CERTIFICATE-----\nYQ==\n-----END CERTIFICATE-----\n",
                    CERTIFICATE.read_text() * 2):
            invalid.write_text(pem)
            with patch.object(unifi, "_read_api_key") as read_key:
                with self.assertRaisesRegex(unifi.UniFiError, "cannot initialize pinned TLS"):
                    unifi.UniFiClient(pinned_certificate=str(invalid)).info()
                read_key.assert_not_called()
        with patch.object(unifi, "PINNED_CERTIFICATE_SHA256", "invalid-pin"), self.assertRaises(unifi.UniFiError):
            self.client()
        with self.assertRaises(unifi.UniFiError):
            unifi.UniFiClient(pinned_certificate="/missing-unifi-certificate.pem")

    def test_verified_legacy_pin_keeps_tls_sni_and_local_trust_enabled(self):
        client = self.client()
        self.addCleanup(client.opener.pool.clear)
        pool = client.opener.pool.connection_from_url(unifi.BASE_URL)
        connection = pool._new_conn()
        context = connection.ssl_context
        self.assertEqual(connection.host, "10.24.24.1")
        self.assertEqual(connection.server_hostname, "unifi.local")
        self.assertIsNone(connection.assert_hostname)
        self.assertIsNone(connection.assert_fingerprint)
        self.assertEqual(context.verify_mode, ssl.CERT_REQUIRED)
        self.assertTrue(context.check_hostname)
        default_flags = ssl.create_default_context().verify_flags
        self.assertEqual(context.verify_flags, default_flags & ~ssl.VERIFY_X509_STRICT)
        self.assertEqual(default_flags ^ context.verify_flags, default_flags & ssl.VERIFY_X509_STRICT)
        self.assertEqual(context.get_ca_certs(binary_form=True), [ssl.PEM_cert_to_DER_cert(CERTIFICATE.read_text())])
        self.assertIsNone(connection.proxy)
        self.assertFalse(pool.retries.total)

    def test_nonpin_transport_preserves_all_default_verification_flags(self):
        default_context = ssl.create_default_context()
        with patch.dict(os.environ, {}, clear=True), patch.object(unifi.urllib.request, "build_opener") as build:
            unifi.UniFiClient()
        context = build.call_args.args[2]._context
        self.assertEqual(context.verify_flags, default_context.verify_flags)
        self.assertEqual(context.verify_mode, ssl.CERT_REQUIRED)
        self.assertTrue(context.check_hostname)

    def test_changed_peer_fails_before_any_http_bytes(self):
        from urllib3.connection import HTTPSConnection

        client = self.client()
        raw_socket = MagicMock()
        tls_socket = MagicMock()
        tls_socket.getpeercert.return_value = b"different peer certificate"
        # Exercise the real urllib3 pool, _validate_conn, TLS wrapper and connect
        # ordering. Only the TCP socket and TLS wire operation are simulated.
        with patch.object(HTTPSConnection, "_new_conn", return_value=raw_socket), patch(
            "urllib3.connection.ssl_wrap_socket", return_value=tls_socket
        ) as wrap, patch.object(HTTPSConnection, "request") as request:
            with self.assertRaises(unifi.UniFiError):
                client.info()
            request.assert_not_called()
        raw_socket.sendall.assert_not_called()
        tls_socket.sendall.assert_not_called()
        tls_socket.close.assert_called()
        self.assertEqual(wrap.call_args.kwargs["server_hostname"], "unifi.local")
        self.assertTrue(wrap.call_args.kwargs["ssl_context"].check_hostname)

    def test_trust_or_expiry_failure_stops_before_http(self):
        from urllib3.connection import HTTPSConnection

        for reason in ("certificate has expired", "invalid CA certificate", "hostname mismatch"):
            client = self.client()
            with patch.object(HTTPSConnection, "_new_conn", return_value=MagicMock()), patch(
                "urllib3.connection.ssl_wrap_socket", side_effect=ssl.SSLCertVerificationError(reason)
            ), patch.object(HTTPSConnection, "request") as request:
                with self.assertRaises(unifi.UniFiError):
                    client.info()
                request.assert_not_called()

    def test_matching_peer_pin_allows_connect_with_hostname_checking(self):
        from urllib3.connection import HTTPSConnection

        client = self.client()
        self.addCleanup(client.opener.pool.clear)
        pool = client.opener.pool.connection_from_url(unifi.BASE_URL)
        connection = pool._new_conn()
        tls_socket = MagicMock()
        tls_socket.getpeercert.return_value = ssl.PEM_cert_to_DER_cert(CERTIFICATE.read_text())
        with patch.object(HTTPSConnection, "_new_conn", return_value=MagicMock()), patch(
            "urllib3.connection.ssl_wrap_socket", return_value=tls_socket
        ):
            connection.connect()
        self.assertTrue(connection.ssl_context.check_hostname)
        self.assertTrue(connection.is_verified)
        connection.close()

    def test_bounded_get_without_proxy_redirect_retry_or_preload_and_cleanup(self):
        import urllib3

        with patch.dict(os.environ, {"HTTPS_PROXY": "http://untrusted-proxy.invalid"}):
            client = self.client()
        response = urllib3.HTTPResponse(status=200, body=io.BytesIO(b'{"value":"dummy-api-key"}'), preload_content=False)
        with patch.object(client.opener.pool, "request", return_value=response) as request, patch.object(
            response, "read", wraps=response.read
        ) as read, patch.object(response, "close", wraps=response.close) as close, patch.object(
            response, "release_conn", wraps=response.release_conn
        ) as release, patch.object(client.opener.pool, "clear") as clear:
            self.assertEqual(client.info(), {"value": "[REDACTED]"})
            read.assert_called_once_with(unifi.MAX_BODY_BYTES + 1)
            close.assert_called_once()
            release.assert_called()
            clear.assert_called_once()
        self.assertEqual(request.call_args.args, ("GET", f"{unifi.BASE_URL}/info"))
        options = request.call_args.kwargs
        self.assertEqual(options["timeout"], 15)
        self.assertFalse(options["redirect"])
        self.assertFalse(options["retries"])
        self.assertFalse(options["preload_content"])
        self.assertIs(type(client.opener.pool), urllib3.PoolManager)

    def test_pinned_failures_redact_and_release(self):
        import urllib3

        cases = [
            urllib3.HTTPResponse(status=200, body=io.BytesIO(b"bad-json"), preload_content=False),
            urllib3.HTTPResponse(status=302, preload_content=False),
            urllib3.HTTPResponse(status=503, preload_content=False),
            urllib3.HTTPResponse(status=200, body=io.BytesIO(b"x" * (unifi.MAX_BODY_BYTES + 1)), preload_content=False),
        ]
        for response in cases:
            client = self.client()
            with patch.object(client.opener.pool, "request", return_value=response), patch.object(
                client.opener.pool, "clear"
            ) as clear, patch.object(response, "close", wraps=response.close) as close:
                with self.assertRaises(unifi.UniFiError):
                    client.info()
                close.assert_called_once()
                clear.assert_called_once()
        client = self.client()
        with patch.object(client.opener.pool, "request", side_effect=urllib3.exceptions.SSLError("dummy-api-key")):
            try:
                client.info()
            except unifi.UniFiError:
                self.assertNotIn("dummy-api-key", traceback.format_exc())
            else:
                self.fail("TLS exception was accepted")

    def test_environment_public_certificate_selects_pinning(self):
        with patch.dict(os.environ, {"UNIFI_PINNED_CERTIFICATE": str(CERTIFICATE)}):
            client = unifi.UniFiClient()
        self.assertIsInstance(client.opener, unifi._PinnedOpener)
        client.opener.pool.clear()


if __name__ == "__main__":
    unittest.main()
