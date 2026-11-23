# The Fleet

When the user names one of these machines, they mean this host. `hostname`
prints the machine you are on (PiHome prints `pi-home`): work locally there.

| Host | What it is | OS | Address | SSH |
|---|---|---|---|---|
| Whopper | Main desktop: KDE Plasma 6, RX 7900 XTX, runs Clokkr | NixOS x86_64 | 10.24.24.5 | `ssh whopper` |
| BigMac | Desktop Mac, Apple silicon, runs Clokkr | nix-darwin | bigmac.local | `ssh bigmac` |
| MacFlurry | MacBook Pro laptop on Wi-Fi | nix-darwin | macflurry.local | `ssh macflurry` |
| BigTasty | Home server: Jellyfin, Plex, the *arr apps, Immich, Paperless, n8n, NocoDB, SearXNG, nginx for `*.theswisscheese.com`, standby DNS | NixOS x86_64 | 10.24.24.2 | `ssh bigtasty` |
| BigKing | NAS: `/volume1`, NFS, Samba, Time Machine | NixOS x86_64 | 10.24.24.3 | `ssh bigking` |
| ShackStack | Living-room HTPC, boots into Steam Gaming Mode | NixOS x86_64 | 10.24.24.7 | `ssh shackstack` |
| PiHome | DNS: AdGuard Home + Unbound on a Raspberry Pi 4, bash shell | NixOS aarch64 | 10.24.24.9 | `ssh pihome` |

Each host's config is `~/.nixfiles/hosts/<host>/`, and the Hosts section of
`~/.nixfiles/README.md` has the full hardware and service list. The checkout
lives on Whopper and the Macs.

## Connecting

- The SSH aliases live on Whopper, BigMac and MacFlurry. They set user
  `psoldunov`, the key and agent forwarding, so remote `sudo` needs no
  password. Other hosts have no aliases and no key the rest accept.
- Run one-shot commands as
  `ssh -o BatchMode=yes -o ConnectTimeout=5 <alias> '<command>'`, so a host
  that is down fails in seconds.
- `fleet status` lists which hosts answer. BigMac, MacFlurry and ShackStack
  are often asleep or away.
- Off the home network, BigTasty and BigKing answer as
  `bigtasty.theswisscheese.com` and `bigking.theswisscheese.com` through
  Cloudflare Access.

## Acting on a host

- Read freely: `systemctl status`, `journalctl`, `df`, `docker ps`,
  non-secret files, Clokkr reads.
- Ask the user first before changing state: restarting a service, any
  `fleet rebuild|update|clean|reboot|sleep|wake`, `rebuild_system`,
  `nixos-rebuild switch`, editing files on the host, Clokkr writes.
- Change a host through `~/.nixfiles` and a deploy; hand edits are lost on
  the next switch.
- Tests stay on the machine running them: a test that reached the hosts once
  rebooted BigTasty and BigKing.

## Clokkr: two machines, two databases

Clokkr runs on Whopper and BigMac, each with its own database, and the
`clokkr` MCP server reads only the machine it runs on. A timesheet, time
report or invoice needs both:

1. This machine: the `clokkr` MCP tools.
2. The other machine: its CLI over ssh, as JSON.
   - From Whopper: `ssh -o BatchMode=yes -o ConnectTimeout=5 bigmac /Applications/Clokkr.app/Contents/MacOS/clokkr sessions --from YYYY-MM-DD --to YYYY-MM-DD --json`
   - From BigMac: the same with `whopper` and `/etc/profiles/per-user/psoldunov/bin/clokkr`.
   - A session carries only a numeric `task` id. Map it with that machine's
     `clokkr tasks --json --archived`: each `nodes[].node` has `id`, `parent`,
     `kind` and `name`.
3. Merge by Folder/Task name. Ids differ between the two databases.

When the other machine does not answer, the timesheet is incomplete: tell the
user which machine's sessions are missing. `fleet wake Whopper` can wake
Whopper (ask first); BigMac has no remote wake.
