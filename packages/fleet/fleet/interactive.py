"""The questions fleet asks on a terminal, through gum."""

from __future__ import annotations

import subprocess

from inventory import Config, Host

MENU = (
    ("rebuild", "switch hosts to the flake as it is"),
    ("update", "bump flake.lock and the pins, then switch"),
    ("clean", "collect garbage, prune docker images, brew cleanup"),
    ("reboot", "restart hosts and wait for them to come back"),
    ("sleep", "suspend hosts"),
    ("wake", "wake hosts with Wake-on-LAN"),
    ("status", "show which hosts answer"),
    ("report", "show the last run's report"),
    ("fix", "hand the last run's problems to an agent"),
)
NO_AGENT = "none: leave it"


class Cancelled(Exception):
    """Esc or Ctrl-C in a menu."""


def choose(cfg: Config, header: str, items: list[str], multi: bool = False, selected: tuple[str, ...] = ()) -> list[str]:
    argv = [cfg.gum, "choose", "--header", header]
    if multi:
        argv.append("--no-limit")
        if selected:
            argv.append("--selected=" + ",".join(selected))
    done = subprocess.run([*argv, "--", *items], stdout=subprocess.PIPE, text=True)
    picked = [line for line in done.stdout.splitlines() if line.strip()]
    if done.returncode != 0 or not picked:
        raise Cancelled
    return picked


def confirm(cfg: Config, question: str, default: bool = True) -> bool:
    done = subprocess.run([cfg.gum, "confirm", f"--default={'true' if default else 'false'}", "--", question])
    if done.returncode not in (0, 1):
        raise Cancelled
    return done.returncode == 0


def _first_word(item: str) -> str:
    return item.split(maxsplit=1)[0]


def pick_action(cfg: Config) -> str:
    width = max(len(name) for name, _ in MENU) + 2
    items = [f"{name:<{width}}{what}" for name, what in MENU]
    return _first_word(choose(cfg, "What should fleet do?", items)[0])


def host_label(cfg: Config, host: Host, online: dict[str, bool]) -> str:
    if cfg.is_local(host):
        state = "this machine"
    elif online.get(host.name):
        state = "online"
    else:
        state = "not answering" + (" (can wake)" if host.wake_mac else "")
    return f"{host.name:<12}{state}"


def pick_hosts(cfg: Config, action: str, candidates: list[Host], online: dict[str, bool]) -> list[Host]:
    """A multi-select of the hosts this action can reach. Rebuild, update and
    clean start with this machine selected, as the old scripts defaulted to it."""
    labels = {host_label(cfg, h, online): h for h in candidates}
    preselect = tuple(label for label, h in labels.items() if cfg.is_local(h) and action in ("rebuild", "update", "clean"))
    header = f"{action}: which hosts? (space selects, ctrl+a selects all, enter confirms)"
    picked = choose(cfg, header, list(labels), multi=True, selected=preselect)
    names = {_first_word(p) for p in picked}
    return [h for h in candidates if h.name in names]


def pick_agent(cfg: Config, agents: list[str]) -> str | None:
    if not agents:
        return None
    picked = _first_word(choose(cfg, "Hand the problems to an agent?", [*agents, NO_AGENT])[0])
    return None if picked == _first_word(NO_AGENT) else picked
