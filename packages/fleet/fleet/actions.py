"""What each action runs for each host, as Steps. These are the commands the
old rebuild_system, update_system and clean_system ran."""

from __future__ import annotations

import shlex

from inventory import Config, Host
from runner import SRC, Step

SYSTEM_BIN = "/run/current-system/sw/bin"
# A remote reboot or suspend can drop the connection before ssh exits cleanly.
DROPPED = frozenset({0, 255})
POWER_SSH = ("-o", "ConnectTimeout=5", "-o", "ServerAliveInterval=5", "-o", "ServerAliveCountMax=2")

# Asks for the target's sudo password once (or takes the forwarded agent) and
# keeps the ticket fresh for the rest of the session, so Homebrew's .pkg
# installs during activation and update_bleeding_edge reuse it. POSIX sh.
REMOTE_KEEP_SUDO = (
    'sudo -v || exit 1; while true; do sudo -n true; sleep 50; done 2>/dev/null & k=$!; trap "kill $k 2>/dev/null" EXIT'
)

# A Mac with its lid closed still answers ssh, but OrbStack has frozen its VM
# for sleep and docker waits forever. So docker gets 20 seconds to answer
# `docker info` (killed, since Go ignores SIGALRM; macOS has no timeout(1))
# and is skipped if it doesn't.
CLEAN = """set -e
sudo "$(command -v nix-collect-garbage)" -d
nix-collect-garbage -d
if command -v docker >/dev/null 2>&1; then
  docker info >/dev/null 2>&1 &
  p=$!
  (sleep 20; kill $p) >/dev/null 2>&1 &
  w=$!
  up=yes
  wait $p || up=no
  kill $w 2>/dev/null || true
  if [ $up = yes ]; then
    docker image prune -a -f
  else
    echo "docker is not answering; skipping docker image prune." >&2
  fi
fi
if [ -x /opt/homebrew/bin/brew ]; then /opt/homebrew/bin/brew cleanup; fi"""


def _ssh(cfg: Config, host: Host, tty: bool, command: str, *options: str) -> tuple[str, ...]:
    return ("ssh", "-t" if tty else "-T", *options, cfg.target(host), command)


def _build_host(cfg: Config, host: Host) -> tuple[str, ...]:
    """Where nixos-rebuild builds a remote NixOS host from a NixOS machine:
    on the builder (Whopper), so a derivation several hosts share compiles
    once; no --build-host when this machine is the builder. A host that
    isn't x86_64 (PiHome) builds itself."""
    builder = cfg.host(cfg.builder) if cfg.builder else None
    if host.builds_itself or builder is None:
        return ("--build-host", cfg.target(host))
    if cfg.is_local(builder):
        return ()
    return ("--build-host", cfg.target(builder))


def route(cfg: Config, host: Host) -> str:
    """How a switch reaches the host, in words for the report."""
    if cfg.is_local(host):
        return "on this machine"
    if host.kind == "nixos" and cfg.local_kind == "nixos":
        build = _build_host(cfg, host)
        where = build[1].split("@")[-1] if build else "this machine"
        return f"nixos-rebuild --target-host {cfg.target(host)}: evaluated here, built on {where}, activated over ssh"
    return "flake copied with `nix flake archive`, then built and activated on the host over ssh"


def switch(cfg: Config, host: Host, tty: bool, extra: tuple[str, ...] = (), after: str | None = None) -> list[Step]:
    """Activate the host from the flake in the current directory. `after` runs
    once the switch succeeded, as the user, in the same session."""
    flake = f".#{host.name}"
    if cfg.is_local(host):
        rebuild = f"{SYSTEM_BIN}/darwin-rebuild" if host.kind == "darwin" else "nixos-rebuild"
        steps = [Step(("sudo", rebuild, "switch", "--flake", flake, "--show-trace", *extra))]
        return steps + ([Step((after,))] if after else [])
    target = cfg.target(host)
    if host.kind == "nixos" and cfg.local_kind == "nixos":
        # --use-substitutes has the target download what cache.nixos.org
        # has itself, so ssh only carries what the builder compiled.
        build = _build_host(cfg, host)
        argv = ("nixos-rebuild", "switch", "--flake", flake, "--target-host", target, *build, "--use-substitutes", "--sudo", "--show-trace", *extra)
        return [Step(argv)]
    # macOS on either end: copy the flake and every input, the private ones
    # included, into the target's store, then build and activate there. An
    # ssh session has no LANG, and nixpkgs bash can crash on macOS 27 without
    # one (NixOS/nixpkgs#570561); macOS sudo keeps LANG.
    store = f"ssh-ng://{target}?remote-program={SYSTEM_BIN}/nix-daemon"
    archive = Step(("nix", "flake", "archive", "--json", "--to", store), captures_src=True)
    rebuild = f"sudo {SYSTEM_BIN}/{host.kind}-rebuild switch --flake {SRC}#{host.name} --show-trace"
    inner = f"{REMOTE_KEEP_SUDO}; export LANG=en_US.UTF-8; {rebuild}{''.join(' ' + shlex.quote(a) for a in extra)}"
    if after:
        inner += f" && {after}"
    return [archive, Step(_ssh(cfg, host, tty, "/bin/sh -c " + shlex.quote(inner)))]


def rebuild(cfg: Config, host: Host, tty: bool) -> list[Step]:
    return switch(cfg, host, tty)


def update(cfg: Config, host: Host, tty: bool) -> list[Step]:
    """Switch with --upgrade-all on NixOS. A Mac also runs update_bleeding_edge
    (Homebrew and mise) after its switch."""
    if host.kind == "nixos":
        return switch(cfg, host, tty, extra=("--upgrade-all",))
    after = cfg.bleeding_edge if cfg.is_local(host) else cfg.remote_bleeding_edge
    return switch(cfg, host, tty, after=after or None)


def clean(cfg: Config, host: Host, tty: bool) -> list[Step]:
    """nix-collect-garbage -d as root and as the user, docker image prune, brew cleanup."""
    if cfg.is_local(host):
        return [Step(("bash", "-c", CLEAN))]
    return [Step(_ssh(cfg, host, tty, "bash -c " + shlex.quote(CLEAN)))]


def reboot(cfg: Config, host: Host, tty: bool) -> list[Step]:
    command = "sudo systemctl reboot" if host.kind == "nixos" else "sudo shutdown -r now"
    if cfg.is_local(host):
        return [Step(tuple(command.split()))]
    return [Step(_ssh(cfg, host, tty, command, *POWER_SSH), ok_codes=DROPPED)]


def sleep(cfg: Config, host: Host, tty: bool) -> list[Step]:
    """Suspend. Locally logind lets the session's user suspend without sudo,
    and pmset sleepnow needs no root on macOS."""
    if host.kind == "darwin":
        command = "pmset sleepnow"
    else:
        command = "systemctl suspend" if cfg.is_local(host) else "sudo systemctl suspend"
    if cfg.is_local(host):
        return [Step(tuple(command.split()))]
    return [Step(_ssh(cfg, host, tty, command, *POWER_SSH), ok_codes=DROPPED)]


def flake_update(cfg: Config) -> list[Step]:
    """update_system's first half: bump flake.lock, then refresh every pin."""
    env = (("FLAKE_DIR", cfg.flake_dir),)
    return [Step(("sudo", "nix", "flake", "update"))] + [Step((pin,), env=env) for pin in cfg.pins]


BUILDERS = {"rebuild": rebuild, "update": update, "clean": clean, "reboot": reboot, "sleep": sleep}
