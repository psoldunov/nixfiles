"""Shared by the tests: fleet's modules on sys.path, and an inventory like the real one."""

import io
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "fleet"))

import inventory  # noqa: E402
from runner import Console  # noqa: E402

HOSTS = [
    {"name": "Whopper", "kind": "nixos", "sleep": True, "wakeMac": "98:b7:85:1f:2c:9a"},
    {"name": "BigTasty", "kind": "nixos"},
    {"name": "BigKing", "kind": "nixos"},
    {"name": "ShackStack", "kind": "nixos", "roaming": True, "sleep": True, "wakeMac": "cc:28:aa:86:dd:6a"},
    {"name": "BigMac", "kind": "darwin", "roaming": True, "sleep": True},
    {"name": "MacFlurry", "kind": "darwin", "roaming": True, "sleep": True},
    {"name": "PiHome", "kind": "nixos", "last": True, "buildsItself": True},
]


def raw_config(local="Whopper"):
    return {
        "localHost": local,
        "sshUser": "psoldunov",
        "builder": "Whopper",
        "hosts": HOSTS,
        "pins": ["/pins/update_claude_code", "/pins/update_codex"],
        "bleedingEdge": "/store/update_bleeding_edge" if local in ("BigMac", "MacFlurry") else None,
        "remoteBleedingEdge": "/etc/profiles/per-user/psoldunov/bin/update_bleeding_edge",
        "gum": "gum",
        "wolBroadcast": "10.24.24.255",
    }


def config(local="Whopper", state="/tmp/fleet-test-state", flake="/tmp/fleet-test-flake"):
    env = {"HOME": "/home/test", "XDG_STATE_HOME": state, "FLAKE_DIR": flake}
    cfg = inventory.load(raw_config(local), env)
    return cfg


def console():
    """A Console writing into a buffer: .text() reads it back."""
    stream = io.TextIOWrapper(io.BytesIO(), encoding="utf-8", write_through=True)
    out = Console(stream)
    out.text = lambda: stream.buffer.getvalue().decode()
    return out
