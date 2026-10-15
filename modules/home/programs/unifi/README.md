# UniFi read-only adapter

This module packages a small client for UniFi's Network Integration API. It exposes eight fixed GET operations through the `unifi-readonly` CLI and an MCP stdio server. It does not provide a generic HTTP client or controller-management writes.

The module is safe to import while disabled. The shared home configuration currently enables it and declares the existing encrypted `UNIFI_API_KEY` SOPS secret. Source configuration does not activate any host.

## Secure bootstrap and enablement

The shared home configuration is imported by Whopper, BigTasty, BigMac, and MacFlurry. After creating a controller API key, edit it only in the secure workspace flow:

```sh
sops secrets/shared.yaml
```

Add a top-level `UNIFI_API_KEY` entry in the SOPS editor and save. SOPS encrypts it before writing `secrets/shared.yaml`. Do not paste the key into chat, command arguments, an ordinary plaintext file, or an unencrypted Git change.

The existing `programs.unifi-readonly.enable = true;` in `modules/home/default.nix` enables the CLI, Claude MCP server, and shared Claude/Pi skill on all four hosts. Build and activate from the worktree containing this change; building a different checkout will not include it. This preparation does not activate the module or rebuild any host.

The wrapper receives only the decrypted secret file path through `UNIFI_API_KEY_FILE`. It reads the key when a request is made, requires restrictive file permissions, and never puts the key in the Nix store or process arguments.

## TLS and controller access

The controller is fixed at `https://10.24.24.1/proxy/network/integration/v1`. TLS verification always stays enabled. With `pinnedCertificate = null` (the module default), the original strict TLS transport checks the IP hostname using system trust or the optional `programs.unifi-readonly.caFile` CA bundle.

The shared configuration sets `programs.unifi-readonly.pinnedCertificate = ./programs/unifi/udm-cert.pem;`. This public leaf certificate is trusted only within the adapter; it does not change global trust, DNS, or the hosts file. The wrapper passes its public store path through `UNIFI_PINNED_CERTIFICATE`. The adapter requires this independently owner-confirmed SHA256 fingerprint of the leaf DER, both for the local PEM and the peer:

```text
4166cadda1eb0d6dd7b9b3f46c21a120150659869cb5e77befb37d805177d521
```

Downloading a certificate without credentials does not establish its identity. The owner independently confirmed this fingerprint before the public certificate was saved. The pinned connection still requires normal CA/expiry verification and hostname verification for `unifi.local`, sent as SNI while connecting directly to `10.24.24.1`. It checks the peer pin during connection setup, before sending HTTP headers or the API key. Redirects, proxies, and retries remain disabled. No insecure fallback exists.

The captured certificate is valid from February 19, 2025 to May 25, 2027. Unmodified Python 3.14 strict verification rejects it with `invalid CA certificate` (verification code 79): its extensions omit Basic Constraints while including Certificate Sign key usage. The owner-approved legacy-UDM compatibility exception clears **only** `VERIFY_X509_STRICT`, only in pinned mode and only after the local PEM matches the immutable SHA256 above. A keyless probe confirmed this single change permits TLS with this exact certificate. Other verification flags remain unchanged; `CERT_REQUIRED` still verifies trust, signature and expiry, native hostname checking remains enabled for `unifi.local`, and the peer must match the exact pin before any HTTP bytes. The non-pinned transport preserves all default verification flags. Never disable additional checks or apply this exception to an unverified replacement.

Certificate replacement or expiry fails closed. Rotation requires a valid replacement certificate, independent owner verification of its SHA256 fingerprint, an explicit update to the public PEM and `PINNED_CERTIFICATE_SHA256` in `unifi_readonly.py`, and regression tests before deployment. Do not automatically trust a newly downloaded certificate.

Use a read-only controller API key or account if the controller UI offers one. The adapter limits its own API surface, but it is not a sandbox: shell agents running as the same OS user can read the decrypted key file and bypass the adapter. The shared key therefore trusts all four hosts. Per-machine rotation is future work, not part of this phase.

## Validation and removal

Offline regression tests run with:

```sh
env PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s modules/home/programs/unifi/tests -p 'test_*.py' -v
```

MCP tests skip when the SDK is absent; pinning tests skip when urllib3 is absent. Run the full suite with Python containing both `mcp` and `urllib3` to exercise the actual stdio handshake and pin-before-HTTP checks. Tests use temporary dummy keys and mocked sockets; they do not contact the router.

After activation, use `unifi-readonly --help` and a bounded command such as `unifi-readonly sites --limit 10`. Claude Code can discover the stdio MCP server, and Pi gets the linked `unifi-readonly` skill through its Claude bridge. No Pi extension or Pi settings change is required.

To stop access, disable `programs.unifi-readonly.enable`, rebuild from this worktree, and revoke the API key in UniFi. This phase intentionally has no management-write tools.
