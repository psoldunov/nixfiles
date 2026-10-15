# nixfiles

Personal NixOS, nix-darwin and home-manager configuration. Multi-host flake, single source of truth.

| Host | Role | Hardware |
|---|---|---|
| **Whopper** | Desktop | AMD Radeon RX 7900 XTX (ROCm, VA-API, gamescope), DP-1 @ 3840x2160@144 HDR, 10 Gbps NIC, KDE Plasma 6 on Wayland |
| **BigTasty** | Home server | Intel iGPU (Quick Sync), mdadm RAID, static IP `10.24.24.2`, NFS + Samba + Netatalk exports, nginx vhosts behind Cloudflare DNS-01 |
| **BigKing** | NAS | ASUSTOR Lockerstor 4 (AS6604T, Celeron J4125), NixOS on an NVMe mirror, ADM's RAID 0 data volume kept as `/volume1`, static IP `10.24.24.3` on an LACP bond, NFS + Samba + Time Machine |
| **BigMac** | Workstation | Apple silicon Mac on macOS, managed by nix-darwin, GUI apps from Homebrew |
| **MacFlurry** | Laptop | MacBook Pro (M1 Pro) on Wi-Fi, managed by nix-darwin like BigMac, with a smaller app set |

Whopper, BigTasty and BigKing share a NixOS baseline (`modules/nixos/`: boot loader, locale, nix settings, users, openssh, sops, docker/libvirt). BigMac and MacFlurry share a nix-darwin baseline (`modules/darwin/`: nix settings, overlays, sops, login shell, sudo, and the Homebrew apps both Macs get). Every host shares a set of home-manager modules (`shell`, `git`, `nix-index`, `sops`, Claude Code and pi config). Whopper and the two Macs also share `modules/home/workstation/`, so their shell, SSH, Claude Code and pi setups match: the same SSH keys and hosts, CLI tools, system scripts, Ghostty config, Playwright and Mailspring MCP servers, and pi. Everything else is host-scoped.

A checkout lives at `~/.nixfiles` on Whopper and on each Mac, and any of them can rebuild any host (see [Deploy](#deploy)).

## Layout

```
.
├── flake.nix                       # Inputs + nixosConfigurations.{Whopper,BigTasty,BigKing} + darwinConfigurations.{BigMac,MacFlurry} + alejandra formatter
├── lib/
│   ├── mkHost.nix                  # Thin nixpkgs.lib.nixosSystem wrapper
│   ├── mkDarwinHost.nix            # Same for nix-darwin's darwinSystem
│   └── ssh-keys.nix                # Public SSH keys: the shared identities and the authorized list
├── modules/                        # SHARED ONLY
│   ├── nixos/                      # NixOS baseline imported by Whopper, BigTasty and BigKing — see "Shared NixOS modules"
│   ├── darwin/                     # nix-darwin baseline imported by both Macs, shared Homebrew list included — see "Macs"
│   └── home/
│       ├── default.nix             # Imports all shared HM modules
│       ├── git/git.nix             # git + gh config
│       ├── shell/shell.nix         # fish/bash/starship/atuin/zoxide/yazi (desktop bits gated)
│       ├── nix-index.nix           # nix-index + shell integrations
│       ├── sops.nix                # HM sops preamble + SHELL_SECRETS
│       ├── programs/claude-code/   # Declarative Claude Code (agents/hooks/skills/rules/MCP/settings)
│       ├── programs/pi/            # Pi coding agent + claude-bridge extension (Claude rules/skills/agents in pi)
│       ├── workstation/            # Whopper + the Macs: SSH, CLI set, system scripts, Ghostty, Playwright/Mailspring MCP, pi
│       └── darwin/                 # The Macs only: CLI extras, mise, Token Station statusline
├── hosts/
│   ├── whopper/
│   │   ├── default.nix             # Imports ./hardware.nix + ./modules
│   │   ├── hardware.nix
│   │   ├── hostConfig.nix          # role=desktop + server flags=false
│   │   ├── mime-defaults.nix       # Default applications, used by xdg.mime
│   │   ├── modules/                # NixOS modules — see "Whopper modules"
│   │   └── home/                   # Whopper-only HM (desktop, dev, programs, scripts, xdg, ...)
│   ├── bigtasty/
│   │   ├── default.nix
│   │   ├── hardware.nix
│   │   ├── hostConfig.nix          # role=server + server flags=true
│   │   ├── modules/                # NixOS modules — see "BigTasty modules"
│   │   │   └── services/           # Pre-extracted service stacks
│   │   └── home/                   # home.nix (shared HM + minimal server bits) + scripts/
│   ├── bigking/
│   │   ├── default.nix             # Imports ./disko.nix + ./hardware.nix + ./modules
│   │   ├── disko.nix               # NVMe layout nixos-anywhere creates: ESP on each drive, mdadm RAID1 root
│   │   ├── hardware.nix
│   │   ├── hostConfig.nix          # role=server
│   │   ├── INSTALL.md              # One-off install over ADM with nixos-anywhere
│   │   ├── modules/                # NixOS modules — see "BigKing modules"
│   │   └── home/                   # home.nix (shared HM only)
│   ├── bigmac/
│   │   ├── default.nix             # Imports ./modules (nix-darwin)
│   │   ├── hostConfig.nix          # role=desktop + server flags=false
│   │   ├── modules/                # modules/darwin + host name + BigMac-only Homebrew apps — see "Macs"
│   │   └── home/                   # Shared HM + workstation layer + modules/home/darwin
│   └── macflurry/                  # Same shape as bigmac/
├── overlays/                       # Custom nixpkgs overlays (claude-code and pi-coding-agent on Whopper + the Macs, the rest Whopper-only)
├── scripts/                        # Helpers: switch-mac.sh, bootstrap-mac.sh, keyring-export.py / keyring-import.py (KWallet migration)
├── secrets/
│   ├── whopper.yaml                # SOPS-encrypted (age, primary recipient)
│   ├── bigtasty.yaml
│   └── shared.yaml                 # Secrets more than one host reads, SSH keys included
└── .ensemblr/settings.toml         # Ensemblr setup + run scripts (check, lint, build, rebuild, update)
```

## Hosts

### Whopper (desktop)

| | |
|---|---|
| GPU | AMD Radeon RX 7900 XTX (amdgpu, OpenCL, VA-API) |
| Display | DP-1 @ 3840x2160@144 with HDR, reasserted at session start by the `force-refresh-rate` user service |
| Network | 10 Gbps NIC (`enp10s0`), static IP `10.24.24.5`, Wake-on-LAN, avahi |
| Filesystem | ext4 root, local `/NVMe` + `/SATA`, 8 NFS mounts under `/mnt` (Media, Files, Documents, Camera, Transmission, SLSKD, Paperless, Games) |
| Desktop | KDE Plasma 6 + SDDM (Wayland only), configured through plasma-manager, Vapor global theme, KWallet as Secret Service, KDE Connect |
| Auth | PAM Yubikey challenge-response + u2f for sudo/login |
| Steam | `programs.steam` + gamescope (3840x2160@144, HDR) + steam-presence wired to `STEAM_API_KEY` / `STEAMGRIDDB_API_KEY` sops secrets |
| Streaming | Sunshine (KMS capture, VA-API encode) for Moonlight clients; switches the monitor to the client's mode per stream — see [hosts/whopper/modules/sunshine](hosts/whopper/modules/sunshine/default.nix) |
| Peripherals | Stream Deck via deckmaster, Solaar (built from the psoldunov/Solaar fork), LibrePods, ZSA/QMK keyboards, HP LaserJet printer |

### BigTasty (server)

| | |
|---|---|
| GPU | Intel iGPU (intel-media-driver, Quick Sync, VAAPI) |
| Storage | mdadm RAID array mounted at `/RAID`, NFS mounts `/mnt/{Media,Backup,Games}` |
| Network | static IP `10.24.24.2` (`enp8s0`), openssh (`AllowUsers psoldunov`) |
| Services | jellyfin, plex, sonarr/radarr/lidarr/prowlarr/seerr, flaresolverr, uptime-kuma, immich, paperless, vaultwarden, infisical, nocodb, n8n, syncthing, sotf-server, concierge-server (Concierge's Sync server) |
| Reverse proxy | nginx vhosts with Cloudflare DNS-01 ACME for `*.theswisscheese.com` |
| Tunnels | `services.cloudflared` tunnel `CFD_MAIN_TUNNEL` (each service module adds its own hostname), `services.cloudflare-dyndns` syncing DNS records |
| Docker | `oci-containers`: slskd, transmission, homeassistant, portainer-ce, homarr (+ watchtower from the shared baseline). Networks created by `systemd.services.docker-networks` (After=docker.service), which also removes unused ones |
| File sharing | `services.nfs.server` exports `/export/{transmission,slskd,Paperless,Files,Documents}`, Samba/samba-wsdd + Netatalk for AFP |
| Passwordless sudo | `pam_ssh_agent_auth` checks forwarded SSH agent against `/etc/ssh/authorized_keys.d/psoldunov` |

### BigKing (NAS)

An ASUSTOR Lockerstor 4 (AS6604T) that ran ADM until NixOS replaced it. [hosts/bigking/INSTALL.md](hosts/bigking/INSTALL.md) has the install steps.

| | |
|---|---|
| Boot | Two Crucial P5 NVMe drives (ADM's old SSD cache): an ESP on each, kept in step by `extraInstallCommands`, and an mdadm RAID1 holding `/` |
| Storage | ADM's data volume as it was: mdadm RAID 0 over the four WD Reds, btrfs subvolume `base` mounted at `/volume1`. ADM itself stays on the eMMC as a fallback |
| Network | static IP `10.24.24.3` on `bond0`, an 802.3ad bond of the two RTL8125 ports (renamed `lan0`/`lan1` by MAC address) |
| File sharing | NFS exports `/volume1/{Media,Camera,Backup,Games}` to the same clients as ADM did, Samba (ADM's fruit settings) with a Time Machine share, samba-wsdd, avahi |
| Services | smartd with temperature warnings |
| Front panel | ASUSTOR kernel drivers (mafredri/asustor-platform-driver), fan control from disk and CPU temperatures, LED triggers, `openlcmd` on the LCD |
| Passwordless sudo | Same as BigTasty |

### Macs (BigMac, MacFlurry)

Both Macs import the same baseline from [modules/darwin](modules/darwin) and the same home-manager layer from [modules/home/darwin](modules/home/darwin). A host's own directory sets its name, its state version and the Homebrew apps only it gets.

| | |
|---|---|
| Hardware | Apple silicon (`aarch64-darwin`). BigMac is reached as `bigmac.local`, MacFlurry (a MacBook Pro on Wi-Fi with a DHCP address) as `macflurry.local` |
| Nix | Upstream Nix, owned by nix-darwin (`nix.enable`); same access-token include as Whopper |
| Shell | Nix's fish as login shell (set during activation). zsh, which macOS apps and Claude Code's Bash tool start, gets the same prompt, tools, aliases, secrets and MCP tokens. Touch ID for sudo |
| Apps | Every GUI app is a Homebrew cask or a Mac App Store app. Apps both Macs get are in [modules/darwin/homebrew.nix](modules/darwin/homebrew.nix); the rest are in each host's own list, [bigmac](hosts/bigmac/modules/homebrew.nix) or [macflurry](hosts/macflurry/modules/homebrew.nix) |
| Runtimes | node, bun, deno and python from mise ([mise.nix](modules/home/darwin/mise.nix)) |
| Claude Code statusline | Token Station from the `psoldunov/tap` cask; its flake is Linux-only |

Where the Macs' software comes from:

| Kind | Source |
|---|---|
| GUI apps | Homebrew casks; App Store-only apps through `homebrew.masApps`. Ghostty's config still comes from [workstation/ghostty.nix](modules/home/workstation/ghostty.nix), shared with Whopper |
| Agent CLIs that release several times a week (codex, mistral-vibe) | Homebrew, upgraded by `update_system` only |
| Tap-only or macOS-only formulae, plus syncthing (runs as a brew service) | Homebrew, the same set on both Macs |
| Claude Code, pi | This repo's overlays (`overlays/claude-code`, `overlays/pi-coding-agent`), same versions as Whopper |
| Every other CLI | nixpkgs: [workstation/cli.nix](modules/home/workstation/cli.nix) + [darwin/packages.nix](modules/home/darwin/packages.nix) |

To give an app to one Mac only, add it to that host's `homebrew.nix`. Put it in the shared file only when both Macs should have it. nix-darwin merges the lists.

Homebrew's `bin` comes after the Nix profiles on `PATH`, so the Nix copy wins when a tool is in both. `rebuild_system` installs missing brew packages but never upgrades them. With `onActivation.cleanup = "uninstall"`, a rebuild removes anything brew has that neither the shared list nor the host's list names. App data stays.

## `hostConfig`

Per-host knobs threaded via `specialArgs`. Shared schema in [hosts/whopper/hostConfig.nix](hosts/whopper/hostConfig.nix), [hosts/bigtasty/hostConfig.nix](hosts/bigtasty/hostConfig.nix), [hosts/bigking/hostConfig.nix](hosts/bigking/hostConfig.nix), [hosts/bigmac/hostConfig.nix](hosts/bigmac/hostConfig.nix) and [hosts/macflurry/hostConfig.nix](hosts/macflurry/hostConfig.nix):

| Field | Type | Meaning |
|---|---|---|
| `role` | `"desktop" \| "server"` | Broad-stroke gate. `modules/home/shell/shell.nix` uses it to omit desktop-only env vars (ghostty/mailspring/prisma/deno), aliases (`suspend`), fish functions (`open`, `fzf_kill`), and the `git` keychain key on servers. macOS vs Linux is not a flag: shared home modules check `pkgs.stdenv.hostPlatform.isDarwin`. |
| `enableRaid`, `enableNfsServer`, `enableSambaShares`, `enableNetatalk`, `enableMediaStack`, `enableArrStack`, `enableNginxVhosts`, `enableCloudflareTunnels`, `enableDyndns`, `enableDockerOci` | bool | Server-side feature flags. All `false` on Whopper, `true` on BigTasty, the storage ones `true` on BigKing. Currently informational — no module reads them; host modules under `hosts/bigtasty/modules/` import unconditionally. Flags reserved for a future host that wants a partial server stack. |

## Shared NixOS modules

[modules/nixos/default.nix](modules/nixos/default.nix) is imported first by each host's `modules/default.nix`. Host modules add to or override this baseline.

| File | Purpose |
|---|---|
| `boot.nix` | systemd-boot (`configurationLimit = 10`), EFI variables, swraid + mdadm `MAILADDR` |
| `locale.nix` | `Asia/Nicosia`, `en_US.UTF-8` with metric `LC_MEASUREMENT` and `en_GB` time |
| `nix.nix` | flakes, `auto-optimise-store`, `trusted-users = ["psoldunov"]`, allowUnfree/Insecure/Broken, nix-ld, `stateVersion` |
| `overlays.nix` | `overlays/claude-code` (Claude Code from Anthropic's `latest` channel) |
| `openssh.nix` | openssh with `AllowUsers psoldunov` |
| `users.nix` | `psoldunov` account (fish, wheel/docker/libvirtd/video) |
| `sops.nix` | sops format + age key path |
| `virtualisation.nix` | docker + libvirtd + containerd, `oci-containers` backend, watchtower |
| `hardware.nix` | `hardware.graphics` (+32-bit), fwupd, Apple SuperDrive udev rule |
| `programs.nix` | fish, mtr, git + lfs, iperf3 |

## Whopper modules

[hosts/whopper/modules/default.nix](hosts/whopper/modules/default.nix) imports:

| File | Purpose |
|---|---|
| `boot.nix` | amdgpu/nfs initrd modules, Plymouth (`nixos-bgrt`), quiet boot, kernel params |
| `desktop-environment.nix` | Plasma 6 + SDDM (Wayland), XDG + mime defaults, Flatpak, partition-manager, KDE Connect (+ firewall 1714-1764), gvfs/udisks2 |
| `fonts.nix` | Font packages (incl. apple-fonts) |
| `hardware.nix` | AMD VA-API/VDPAU packages, OpenCL, Logitech/Solaar, Bluetooth, LibrePods, xone, SANE, printer, Stream Deck udev rule |
| `mounts.nix` | `/NVMe`, `/SATA`, NFS mounts under `/mnt` |
| `networking.nix` | hostname, static IP on `enp10s0`, firewall ports, openssh hardening, avahi, Skrepka firewall |
| `nix.nix` | nix-path, nix-gaming Cachix substituter, idle daemon scheduling, `max-jobs`/`cores` |
| `overlays.nix` | catppuccin-vsc, ensemblr, and the local overlays (mpv-mpris, vapor-kde, duckstation, motrix, pi-coding-agent, bambu-studio, periphery, solaar) |
| `packages.nix` | System packages, unfree/insecure allowances, Steam + steam-presence, gamescope, gamemode, nano, 1Password |
| `security.nix` | polkit, rtkit, PAM Yubikey + u2f, gnupg agent |
| `services.nix` | vscode-server, syncthing, and other desktop services |
| `sops.nix` | Whopper system secrets |
| `sunshine/` | Sunshine game streaming + per-stream display mode script |
| `users.nix` | Extra groups for `psoldunov` (disk, i2c, input, uinput, scanner, lp, librepods, ...) |
| `virtualisation.nix` | Whopper containers (portainer agent) |

## BigTasty modules

[hosts/bigtasty/modules/default.nix](hosts/bigtasty/modules/default.nix) imports:

| File | Purpose |
|---|---|
| `boot.nix` | kvm-intel, blacklisted nvidia/nouveau, `vm.overcommit_memory` sysctl, iHD VA-API driver |
| `networking.nix` | hostname, static IP, firewall ports, openssh (`PrintMotd=false`, `PrintLastLog=false`), `pam_ssh_agent_auth`, sudo `env_keep SSH_AUTH_SOCK` |
| `hardware.nix` | Intel media/VA-API/compute packages, intel-gpu-tools, cachefilesd (`/RAID/cachefilesd`), nbd.server (cdrom), powertop, mdmonitor |
| `filesystems.nix` | `/RAID` ext4, NFS mounts, bind mounts for `/export/*` |
| `users.nix` | `psoldunov` extras (`media` group, linger, declarative `openssh.authorizedKeys.keys`), `cloudflared` system user |
| `nix-locale.nix` | `permittedInsecurePackages` for .NET 6 (locale and base nix settings are shared) |
| `packages.nix` | Server-side `environment.systemPackages` |
| `services-media.nix` | jellyfin, plex (library in `/var/lib/plex`, copied from ADM's Plex on BigKing; Quick Sync through `/dev/dri/renderD128`; requires the `/mnt/Media` mount), uptime-kuma, *arr stack (sonarr/radarr/lidarr/prowlarr/seerr), flaresolverr (Prowlarr Cloudflare proxy), `programs.chromium` |
| `services-web.nix` | nginx vhosts + ACME with Cloudflare DNS-01 |
| `services-cloudflare.nix` | `services.cloudflared` tunnel `CFD_MAIN_TUNNEL`, `services.cloudflare-dyndns` |
| `services-shares.nix` | `services.nfs.server`, Samba (workgroup WORKGROUP, MacSamba/fruit), samba-wsdd, netatalk, `systemd.services.sharesSync` (inotify → rsync) |
| `services-misc.nix` | gnupg agent |
| `virtualisation.nix` | Host `oci-containers`, transmission restart policy, `systemd.services.docker-networks` oneshot creating immich-/paperless-/nocodb-/infisical-network |
| `sops.nix` | sops secrets for env files referenced by docker containers + ACME |
| `services/` | Pre-extracted service modules: `immich`, `paperless`, `syncthing`, `sotf-server`, `n8n`, `nocodb`, `vaultwarden`, `infisical`, `concierge-server` |

## BigKing modules

[hosts/bigking/modules/default.nix](hosts/bigking/modules/default.nix) imports:

| File | Purpose |
|---|---|
| `asustor/` | `hardware.asustor` drivers (it87 mainline drivers blacklisted, `acpi_enforce_resources=lax`), `asustor-fan` (pwm1 from drivetemp and coretemp), `asustor-leds` (disk, LAN and status LED triggers), `openlcmd` built from `lcm` |
| `boot.nix` | Copies `/boot` to `/boot-fallback` after each bootloader install, zram swap, `stateVersion` 26.11 |
| `filesystems.nix` | `/volume1`: ADM's btrfs on the RAID 0, `subvol=base`, `nofail` |
| `hardware.nix` | smartd (self-tests, warns above 45 °C), lm_sensors, mdmonitor to syslog |
| `networking.nix` | hostname, `lan0`/`lan1` link names, `bond0`, static IP, NFS firewall ports, openssh, `pam_ssh_agent_auth` |
| `services-shares.nix` | `services.nfs.server`, Samba, samba-wsdd, avahi Time Machine advert; NFS and Samba require the `/volume1` mount |
| `users.nix` | `psoldunov` pinned to uid 1000, ADM's `admin` (uid 999) and `administrators` (gid 999) declared so the ids stay theirs |

## Flake inputs

| Input | Purpose |
|---|---|
| `nixpkgs` | nixos-unstable — default package set |
| `nixpkgs-stable` | nixos-25.05 — calibre, Obsidian, prisma-engines |
| `home-manager` | NixOS module on Whopper, BigTasty and BigKing, nix-darwin module on the Macs |
| `disko` | BigKing's NVMe partitioning, used by nixos-anywhere at install time |
| `asustor-platform-driver`, `lcm` | BigKing's ASUSTOR kernel drivers (NixOS module) and the source of its LCD daemon |
| `nix-darwin` | The Macs' system layer |
| `plasma-manager` | Whopper declarative KDE Plasma config |
| `sops-nix` | NixOS + HM secret management |
| `nix-gaming` | Whopper pipewire low-latency + platform-optimizations |
| `nix-flatpak` | Whopper Flatpak declarations |
| `catppuccin`, `catppuccin-vsc` | Whopper. The catppuccin modules are imported with theming off; catppuccin-vsc supplies the VS Code theme |
| `vscode-server` | Both hosts — VS Code Remote-SSH support |
| `zen-browser`, `apple-fonts` | Whopper |
| `steam-presence` | Whopper Steam Discord presence |
| `skrepka` | Whopper clipboard history with LAN sync (HM module + NixOS firewall ports) |
| `ensemblr` | Whopper overlay providing `ensemblr` / `ensemblr-master` |
| `token-station` | Whopper tray monitor for Claude Code and Codex plan usage |
| `solaar` | Non-flake source for `overlays/solaar.nix` (psoldunov/Solaar fork) |
| `context-mode`, `caveman` | Claude Code plugin sources |

## Adding a new host

1. `mkdir hosts/<name>` and create `hardware.nix` (from `nixos-generate-config --show-hardware-config`), `hostConfig.nix`, `default.nix`, `modules/default.nix` and a home module. `modules/default.nix` imports `../../../modules/nixos`; the home module imports `../../../modules/home`.
2. Add one entry to [flake.nix](flake.nix):
   ```nix
   nixosConfigurations.<Name> = mkHost {
     inherit system;
     specialArgs = {
       inherit inputs outputs pkgs-stable;
       hostConfig = import ./hosts/<name>/hostConfig.nix;
     };
     modules = [
       ./hosts/<name>/default.nix
       sops-nix.nixosModules.sops
       home-manager.nixosModules.home-manager
       # plus whatever extra modules this host needs
       {
         home-manager = {
           extraSpecialArgs = { inherit inputs outputs pkgs-stable; hostConfig = ...; };
           useGlobalPkgs = true;
           useUserPackages = true;
           backupFileExtension = "hm-backup";
           overwriteBackup = true;
           users.psoldunov = import ./hosts/<name>/home/home.nix;
           sharedModules = [ sops-nix.homeManagerModules.sops ];
         };
       }
     ];
   };
   ```
3. Create `secrets/<name>.yaml` and add a matching `creation_rules` entry to [.sops.yaml](.sops.yaml).
4. Add `<Name>` to `ALL_HOSTS` and `KIND` in [modules/home/workstation/scripts.nix](modules/home/workstation/scripts.nix) so `rebuild_system <Name>` and `all` know it.

A macOS host follows [hosts/macflurry](hosts/macflurry) instead: copy its directory, add `<Name> = mkMac "<name>";` to `darwinConfigurations` in [flake.nix](flake.nix), and use `KIND=darwin`. Remote sudo also needs a `sudo-<name>` key: its public half in [lib/ssh-keys.nix](lib/ssh-keys.nix) (`identities`, `authorized` and `sudo`), its private half as `SSH_KEY_SUDO_<NAME>` in `secrets/shared.yaml`, and a host block in [workstation/ssh.nix](modules/home/workstation/ssh.nix). Then bootstrap it (see [Bootstrapping a Mac](#bootstrapping-a-mac)).

## Deploy

`rebuild_system` is host-aware. It lives in the workstation scripts ([modules/home/workstation/scripts.nix](modules/home/workstation/scripts.nix)), so Whopper and the Macs have it and BigTasty doesn't. It runs locally when the argument is the current host (`nixos-rebuild` or `darwin-rebuild`). Otherwise it works on `psoldunov@<host>`:

- Linux to Linux (Whopper to BigTasty or BigKing): `nixos-rebuild --target-host --build-host --sudo`, as before.
- Anything involving macOS: `nix flake archive --to ssh-ng://<host>` copies the flake and every input, private ones included, into the target's store. Then `ssh -t <host> sudo <nixos|darwin>-rebuild switch` builds and activates it there. sudo asks for the target's password once, and the session keeps that ticket alive for Homebrew's `.pkg` installs and, under `update_system`, for `update_bleeding_edge`. Like `--target-host`, this deploys the local working tree.

```fish
rebuild_system                # rebuild current host locally
rebuild_system Whopper        # explicit local
rebuild_system BigTasty       # remote build + activate via SSH agent
rebuild_system BigKing        # same for the NAS
rebuild_system BigMac         # from Whopper: copy the flake, build and switch on the Mac
rebuild_system MacFlurry      # same for the laptop
rebuild_system all            # Whopper, BigTasty, BigKing, BigMac, MacFlurry, in parallel; skips MacFlurry when it doesn't answer
update_system [host|all]      # same shape; runs `nix flake update` + update_claude_code, update_duckstation, update_motrix, update_pi_coding_agent first, switches with --upgrade-all (NixOS); on the Macs also brew update/upgrade + mise upgrade
clean_system [host|all]       # nix-collect-garbage -d (sudo + user) + docker image prune, + brew cleanup on the Macs
```

`rebuild_system` and `update_system` work in `~/.nixfiles` (or `$FLAKE_DIR`). Every workstation commits there, so they first run `git pull --rebase --autostash`. A conflict stops the script. Then they `git add -A`, and after a successful switch they commit everything (`rebuild commit <date>` / `update commit <date>`) and push.

`all` switches the hosts in parallel, after `update_system` has run `nix flake update` and the pin scripts. If the local host is one of them, sudo asks for its password first. The remote hosts authenticate with the forwarded agent, so nothing prompts once the builds start. Each output line starts with `[Host]`, and each host's output also goes to its own log under `$TMPDIR`. The script waits for every host and commits only if all of them succeeded. When one fails, it names the host and keeps the logs. Ctrl-C stops every host.

MacFlurry is a laptop, so it is often asleep or away. `all` checks it first with a 5-second `ssh` that can't prompt. If it doesn't answer, the script prints a warning and runs the other hosts without it. The other hosts are not checked this way: when one of them is down, `all` fails. `ROAMING_HOSTS` in [scripts.nix](modules/home/workstation/scripts.nix) lists the hosts that get the check. The check runs in batch mode, so it also skips the laptop until the machine running `all` has its host key in `known_hosts`.

Inside an Ensemblr worktree, use the run scripts in [.ensemblr/settings.toml](.ensemblr/settings.toml) instead. They target the worktree's flake (`.#<Host>`) and leave staging and committing to you.

When deploying from a machine that is not managed by this flake, the helper scripts
and `nixos-rebuild` may not exist on `$PATH`. Use the full command from a checkout
of this repo:

```sh
nix run nixpkgs#nixos-rebuild -- switch --flake .#BigTasty --target-host psoldunov@bigtasty --build-host psoldunov@bigtasty --sudo --show-trace
```

Use `dry-activate` instead of `switch` for a remote activation preview.

### Bootstrapping a Mac

The first switch can't use `rebuild_system`, because the Mac has no nix-darwin yet. [scripts/bootstrap-mac.sh](scripts/bootstrap-mac.sh) does it from Whopper:

1. On the Mac: `sudo /nix/nix-installer uninstall` (removes Determinate Nix, leaves Homebrew alone).
2. On the Mac: install upstream Nix, `sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)`.
3. On Whopper: `scripts/bootstrap-mac.sh <Host>`, for example `scripts/bootstrap-mac.sh MacFlurry` (or the `bootstrap-macflurry` run script).

The script reaches the Mac as `<host>.local` with your usual keys, because the Mac only accepts its sudo key after this switch. It appends the sops age identity to the Mac's `keys.txt` and copies the flake over. It backs up every file the switch replaces to `~/pre-nix-backup-<date>.tar.gz`, moves `~/.claude/settings.json` aside, then builds and switches. The switch runs the Homebrew cleanup too, so it uninstalls every formula and cask the two lists don't name. Read them against the Mac before step 3. After that, clone the repo to `~/.nixfiles` on the Mac and use `rebuild_system` from any workstation.

### Silent remote sudo

`rebuild_system BigTasty` runs without prompting because of the four settings below. BigKing has the same ones (its `bigking` host block, [networking.nix](hosts/bigking/modules/networking.nix), and the baseline's authorized keys).

1. The `bigtasty` host block in [modules/home/workstation/ssh.nix](modules/home/workstation/ssh.nix) (Whopper and the Macs): `ForwardAgent = true`.
2. BigTasty's [networking.nix](hosts/bigtasty/modules/networking.nix) enables `security.pam.sshAgentAuth` and adds `security.pam.services.sudo.sshAgentAuth = true`.
3. BigTasty sudo: `Defaults env_keep += "SSH_AUTH_SOCK"`.
4. The forwarded agent's key matches `/etc/ssh/authorized_keys.d/psoldunov` declared in [users.nix](hosts/bigtasty/modules/users.nix).

Bootstrap: if the very first deploy needs a sudo password (no NOPASSWD yet on a fresh box), drop `%wheel ALL=(ALL) NOPASSWD: ALL` into `/etc/sudoers.d/99-bootstrap` once, deploy, then remove.

Whopper and the two Macs work the same way in every direction, with one difference: each one's sudo accepts only its own dedicated key (`sudo-whopper`, `sudo-bigmac`, `sudo-macflurry` in [lib/ssh-keys.nix](lib/ssh-keys.nix)), never the GitHub key. The `whopper`, `bigmac` and `macflurry` host blocks log in with that key, so `AddKeysToAgent` puts it in the connecting machine's agent and `ForwardAgent` hands it over. A machine never loads its own sudo key, so sudo at the machine itself still asks for the YubiKey (Whopper) or Touch ID (the Macs).

- Whopper: `security.pam.sshAgentAuth` with `/etc/ssh/sudo_authorized_keys`, in [security.nix](hosts/whopper/modules/security.nix).
- The Macs: nixpkgs builds `pam_ssh_agent_auth` for Linux only, so [overlays.nix](modules/darwin/overlays.nix) builds it for macOS. [system.nix](modules/darwin/system.nix) picks the host's key by its lower-cased name, puts the module ahead of Touch ID in `/etc/pam.d/sudo_local` and installs `/etc/ssh/sudo_authorized_keys` as a real root-owned file, since the module rejects key files under `/nix/store`.

## Secrets

- **Backend**: sops-nix + age. Primary recipient declared in [.sops.yaml](.sops.yaml).
- **Files**: `secrets/whopper.yaml`, `secrets/bigtasty.yaml`, `secrets/shared.yaml`. Each host pins its own `sops.defaultSopsFile` (`hosts/<host>/modules/sops.nix` + its home module). Entries more than one host needs point at `shared.yaml` with a per-secret `sopsFile`. The Macs and BigKing have no file of their own and read `shared.yaml`.
- **Age key path on each host**: `~/.config/sops/age/keys.txt`. It must hold the primary identity; `scripts/bootstrap-mac.sh` adds it on a Mac.

Notable secrets:

| Secret | Host | Consumer |
|---|---|---|
| `STEAM_API_KEY`, `STEAMGRIDDB_API_KEY` | Whopper system | `programs.steam.presence` |
| `SUNSHINE_WEB_PASSWORD` | Whopper system | Sunshine web UI login, written before each start |
| `SYNCTHING_GUI_PASSWORD` | both (system, `shared.yaml`) | `services.syncthing.guiPasswordFile` |
| `WIFI_PASSWORD` | BigTasty (system, `shared.yaml`) | wpa_supplicant `secretsFile`, rendered by a sops template (only while `networking.wireless` is enabled) |
| `SHELL_SECRETS` | Whopper, BigKing + the Macs (user, `shared.yaml`); BigTasty has its own | fish/bash init in shared `shell.nix`; shell-only env exports |
| `SSH_KEY_GITHUB`, `SSH_KEY_ID_ED25519`, `SSH_KEY_ID_RSA`, `SSH_KEY_AGENCY_VPS`, `SSH_KEY_FLYWHEEL`, `SSH_KEY_SECRETS`, `SSH_KEY_GIT_SK`, `SSH_KEY_SUDO_*` | Whopper + the Macs (user, `shared.yaml`) | linked to `~/.ssh/<name>` by [workstation/ssh.nix](modules/home/workstation/ssh.nix); public halves in [lib/ssh-keys.nix](lib/ssh-keys.nix) |
| `NIX_ACCESS_TOKENS` | Whopper + the Macs (system, `shared.yaml`) | GitHub token for the private flake inputs, included into nix.conf |
| `CLAUDE_SANITY_MCP_BEARER`, `N8N_ACCESS_TOKEN`, `NOCODB_API_KEY`, `PAPERLESS_API_KEY` | all hosts (user, `shared.yaml`) | Claude Code MCP servers ([mcp.nix](modules/home/programs/claude-code/mcp.nix)) |
| `SPOTIFYD_PASSWORD` | Whopper (user) | spotifyd `password_cmd` |
| `CFD_MAIN_TUNNEL`, `CFDYNDNS_TOKEN`, `CF_DNS_CREDS` | BigTasty | cloudflared, cloudflare-dyndns, ACME DNS-01 |
| `SLSKD_ENV`, `HOMARR_SETTINGS`, `IMMICH_SETTINGS`, ... | BigTasty | `virtualisation.oci-containers.containers.*.environmentFiles` |

### Editing

```fish
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops edit secrets/whopper.yaml
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops edit secrets/bigtasty.yaml
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops edit secrets/shared.yaml
```

On Whopper and the Macs, `sops-code <file>` opens the same editor session in VS Code.

## Inspect

```fish
nix flake check --no-build
nix eval .#nixosConfigurations.Whopper.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.BigTasty.config.system.build.toplevel.drvPath
nix eval .#darwinConfigurations.BigMac.system.drvPath     # evaluates on Linux too; building needs the Mac
nix eval .#darwinConfigurations.MacFlurry.system.drvPath
nixos-rebuild dry-activate --flake .#BigTasty --target-host psoldunov@bigtasty --sudo
```

## Conventions

- **`/modules` is shared-only.** Anything host-specific lives under `hosts/<host>/`. Shared modules hold the host-agnostic baseline; hosts append to lists and attrsets rather than redefine them.
- **`hostConfig` over `mkOption`.** No formal module options for now; flags threaded via `specialArgs`. Upgrade if/when a third host needs diverging settings.
- **Scripts on `$PATH`.** Everything in `modules/home/workstation/scripts.nix` and `hosts/whopper/home/scripts/` lands in `home.packages`, so other modules and shortcuts call scripts by bare name, not by Nix store path.
- **Closure isolation.** Shared modules that pull desktop-heavy deps (ghostty, mailspring, prisma-engines) must gate them behind `lib.optionalAttrs (hostConfig.role == "desktop")` — see [modules/home/shell/shell.nix](modules/home/shell/shell.nix) for the pattern.
- **Flake visibility.** `nix flake` only sees git-tracked files. `git add` new files before `nixos-rebuild build`.
- **Formatting**: alejandra, exposed as the flake formatter. `nix fmt -- flake.nix lib hosts modules overlays`.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `path 'X' does not exist` during eval | New file not `git add`ed |
| Sudo password prompted on remote deploy | `pam_ssh_agent_auth` not yet active (first deploy on a fresh box); use bootstrap sudoers.d |
| `error: cannot add path ... because it lacks a signature by a trusted key` | Target host's `nix.settings.trusted-users` doesn't include `psoldunov`; or omit `--build-host` and let target build locally |
| Docker container activation fails on first switch | `systemd.services.docker-networks` is After=docker.service — if docker.service stopped during activation, networks aren't there yet; retry deploy |
| Home-manager activation fails with "would be clobbered" | A desktop app rewrote an HM-owned file; `overwriteBackup = true` in `flake.nix` should handle it, else remove the stale `<file>.hm-backup` |
| Stale `home-manager` generation | `systemctl status home-manager-psoldunov && journalctl -u home-manager-psoldunov -b` |

## History

The repo started as a single-host Whopper monolith (`modules/nixos/configuration.nix` ~1000 lines + `home-manager/home.nix` ~445 lines), got refactored into per-concern modules, then merged with the `psoldunov/nixfiles-server` repo to become multi-host. BigTasty's old 700-line `configuration.nix` was decomposed into focused modules under `hosts/bigtasty/modules/` during the merge. The settings both hosts duplicated were later pulled into the shared `modules/nixos/` baseline, and Whopper moved from Hyprland to KDE Plasma 6.
