"""The hosts fleet knows, read from the config Nix writes, and how to reach them:
ssh probes and Wake-on-LAN."""

from __future__ import annotations

import os
import re
import socket
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

KINDS = ("nixos", "darwin")
_MAC = re.compile(r"^[0-9a-fA-F]{2}(?::[0-9a-fA-F]{2}){5}$")
PROBE_TIMEOUT = 15
SSH_PROBE = ("-o", "ConnectTimeout=5", "-o", "BatchMode=yes")


class UsageError(Exception):
    """A mistake in what was asked for; main prints it and exits 2."""


@dataclass(frozen=True)
class Host:
    name: str
    kind: str
    # Often asleep or away: `all` skips it when it doesn't answer.
    roaming: bool = False
    # Others resolve names through it, so it switches alone after them.
    last: bool = False
    # Not x86_64, so it builds its own system instead of the builder.
    builds_itself: bool = False
    sleep: bool = False
    wake_mac: str | None = None


@dataclass(frozen=True)
class Config:
    local_host: str
    ssh_user: str
    hosts: tuple[Host, ...]
    flake_dir: str
    state_dir: str
    builder: str = ""
    pins: tuple[str, ...] = ()
    bleeding_edge: str | None = None
    remote_bleeding_edge: str = ""
    gum: str = "gum"
    wol_broadcast: str = "255.255.255.255"

    def target(self, host: Host) -> str:
        """The ssh destination: <user>@<lower-cased name>, as in the ssh config."""
        return f"{self.ssh_user}@{host.name.lower()}"

    def host(self, name: str) -> Host | None:
        return next((h for h in self.hosts if h.name.lower() == name.lower()), None)

    def is_local(self, host: Host) -> bool:
        return host.name == self.local_host

    @property
    def local_kind(self) -> str:
        local = self.host(self.local_host)
        if local:
            return local.kind
        return "darwin" if sys.platform == "darwin" else "nixos"


def _host(raw: dict) -> Host:
    name, kind, mac = raw.get("name"), raw.get("kind"), raw.get("wakeMac")
    if not isinstance(name, str) or not name:
        raise ValueError(f"host without a name: {raw!r}")
    if kind not in KINDS:
        raise ValueError(f"{name}: kind must be one of {', '.join(KINDS)}")
    if mac is not None and not _MAC.match(mac):
        raise ValueError(f"{name}: wakeMac {mac!r} is not a MAC address")
    return Host(
        name=name,
        kind=kind,
        roaming=bool(raw.get("roaming", False)),
        last=bool(raw.get("last", False)),
        builds_itself=bool(raw.get("buildsItself", False)),
        sleep=bool(raw.get("sleep", False)),
        wake_mac=mac,
    )


def load(raw: dict, env: dict | None = None) -> Config:
    """The Config from the JSON Nix passes as the first argument."""
    env = os.environ if env is None else env
    home = Path(env.get("HOME", "~")).expanduser()
    state = env.get("XDG_STATE_HOME") or str(home / ".local" / "state")
    return Config(
        local_host=raw["localHost"],
        ssh_user=raw["sshUser"],
        hosts=tuple(_host(h) for h in raw["hosts"]),
        flake_dir=env.get("FLAKE_DIR") or str(home / ".nixfiles"),
        state_dir=str(Path(state) / "fleet"),
        builder=raw.get("builder", ""),
        pins=tuple(raw.get("pins", ())),
        bleeding_edge=raw.get("bleedingEdge"),
        remote_bleeding_edge=raw.get("remoteBleedingEdge", ""),
        gum=raw.get("gum", "gum"),
        wol_broadcast=raw.get("wolBroadcast", "255.255.255.255"),
    )


def resolve(cfg: Config, names: list[str]) -> tuple[list[Host], bool]:
    """The hosts the names stand for, in inventory order, and whether they
    came from `all` (which lets the run skip roaming hosts that don't answer)."""
    if any(n.lower() == "all" for n in names):
        if len(names) > 1:
            raise UsageError("`all` can't be combined with host names")
        return list(cfg.hosts), True
    wanted = set()
    for name in names:
        host = cfg.host(name)
        if host is None:
            known = " ".join(h.name for h in cfg.hosts)
            raise UsageError(f"unknown host '{name}' (known: {known} all)")
        wanted.add(host.name)
    return [h for h in cfg.hosts if h.name in wanted], False


def reachable(target: str) -> bool:
    """Whether ssh gets in within a few seconds, without prompting for anything."""
    try:
        done = subprocess.run(
            ["ssh", *SSH_PROBE, target, "true"],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=PROBE_TIMEOUT,
        )
    except (subprocess.TimeoutExpired, OSError):
        return False
    return done.returncode == 0


def probe(cfg: Config, hosts: list[Host], reach: Callable[[str], bool] = reachable) -> dict[str, bool]:
    """Which of the hosts answer, checked at once. This machine always does."""
    remote = [h for h in hosts if not cfg.is_local(h)]
    answers = {h.name: True for h in hosts if cfg.is_local(h)}
    if remote:
        with ThreadPoolExecutor(max_workers=len(remote)) as pool:
            for host, up in zip(remote, pool.map(lambda h: reach(cfg.target(h)), remote), strict=True):
                answers[host.name] = up
    return answers


def magic_packet(mac: str) -> bytes:
    if not _MAC.match(mac):
        raise ValueError(f"{mac!r} is not a MAC address")
    return b"\xff" * 6 + bytes.fromhex(mac.replace(":", "")) * 16


def send_wake(mac: str, broadcast: str) -> None:
    """Send the Wake-on-LAN magic packet a few times to the subnet broadcast,
    so it leaves on the LAN interface even when another holds the default route."""
    packet = magic_packet(mac)
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        for _ in range(3):
            sock.sendto(packet, (broadcast, 9))
