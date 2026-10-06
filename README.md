# nixfiles

Personal NixOS + home-manager configuration. Multi-host flake, single source of truth.

| Host | Role | Hardware |
|---|---|---|
| **Whopper** | Desktop | AMD Radeon RX 7900 XTX (ROCm, VA-API, gamescope), DP-1 @ 3840x2160@144 HDR, 10 Gbps NIC, KDE Plasma 6 on Wayland |
| **BigTasty** | Home server | Intel iGPU (Quick Sync), mdadm RAID, static IP `10.24.24.2`, NFS + Samba + Netatalk exports, nginx vhosts behind Cloudflare DNS-01 |

Both hosts share a NixOS baseline (`modules/nixos/`: boot loader, locale, nix settings, users, openssh, sops, docker/libvirt) and a set of home-manager modules (`shell`, `git`, `nix-index`, `sops`, Claude Code config). Everything else is host-scoped.

## Layout

```
.
├── flake.nix                       # Inputs + nixosConfigurations.{Whopper,BigTasty} + alejandra formatter
├── lib/
│   └── mkHost.nix                  # Thin nixpkgs.lib.nixosSystem wrapper
├── modules/                        # SHARED ONLY
│   ├── nixos/                      # NixOS baseline imported by both hosts — see "Shared NixOS modules"
│   └── home/
│       ├── default.nix             # Imports all shared HM modules
│       ├── git/git.nix             # git + gh config
│       ├── shell/shell.nix         # fish/bash/starship/atuin/zoxide/yazi (desktop bits gated)
│       ├── nix-index.nix           # nix-index + shell integrations
│       ├── sops.nix                # HM sops preamble + SHELL_SECRETS
│       ├── programs/claude-code/   # Declarative Claude Code (agents/hooks/skills/rules/MCP/settings)
│       └── programs/pi/            # Pi coding agent + claude-bridge extension (Claude rules/skills/agents in pi)
├── hosts/
│   ├── whopper/
│   │   ├── default.nix             # Imports ./hardware.nix + ./modules
│   │   ├── hardware.nix
│   │   ├── hostConfig.nix          # role=desktop + server flags=false
│   │   ├── mime-defaults.nix       # Default applications, used by xdg.mime
│   │   ├── modules/                # NixOS modules — see "Whopper modules"
│   │   └── home/                   # Whopper-only HM (desktop, dev, programs, scripts, xdg, ...)
│   └── bigtasty/
│       ├── default.nix
│       ├── hardware.nix
│       ├── hostConfig.nix          # role=server + server flags=true
│       ├── modules/                # NixOS modules — see "BigTasty modules"
│       │   └── services/           # Pre-extracted service stacks
│       └── home/                   # home.nix (shared HM + minimal server bits) + scripts/
├── overlays/                       # Custom nixpkgs overlays (claude-code shared, the rest Whopper-only)
├── scripts/                        # One-off helpers (keyring-export.py / keyring-import.py for the KWallet migration)
├── secrets/
│   ├── whopper.yaml                # SOPS-encrypted (age, primary recipient)
│   ├── bigtasty.yaml
│   └── shared.yaml                 # Secrets both hosts read
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
| Services | jellyfin, sonarr/radarr/lidarr/prowlarr/seerr, flaresolverr, uptime-kuma, immich, paperless, vaultwarden, infisical, nocodb, n8n, syncthing, sotf-server |
| Reverse proxy | nginx vhosts with Cloudflare DNS-01 ACME for `*.theswisscheese.com` |
| Tunnels | `services.cloudflared` tunnel `CFD_MAIN_TUNNEL` (each service module adds its own hostname), `services.cloudflare-dyndns` syncing DNS records |
| Docker | `oci-containers`: jellyplex-watched, slskd, transmission, homeassistant, portainer-ce, homarr (+ watchtower from the shared baseline). Networks created by `systemd.services.docker-networks` (After=docker.service), which also removes unused ones |
| File sharing | `services.nfs.server` exports `/export/{transmission,slskd,Paperless,Files,Documents}`, Samba/samba-wsdd + Netatalk for AFP |
| Passwordless sudo | `pam_ssh_agent_auth` checks forwarded SSH agent against `/etc/ssh/authorized_keys.d/psoldunov` |

## `hostConfig`

Per-host knobs threaded via `specialArgs`. Shared schema in [hosts/whopper/hostConfig.nix](hosts/whopper/hostConfig.nix) and [hosts/bigtasty/hostConfig.nix](hosts/bigtasty/hostConfig.nix):

| Field | Type | Meaning |
|---|---|---|
| `role` | `"desktop" \| "server"` | Broad-stroke gate. `modules/home/shell/shell.nix` uses it to omit desktop-only env vars (kitty/thunderbird/prisma/deno), aliases (`suspend`), fish functions (`open`, `fzf_kill`), and the `git` keychain key on servers. |
| `enableRaid`, `enableNfsServer`, `enableSambaShares`, `enableNetatalk`, `enableMediaStack`, `enableArrStack`, `enableNginxVhosts`, `enableCloudflareTunnels`, `enableDyndns`, `enableDockerOci` | bool | Server-side feature flags. All `false` on Whopper, `true` on BigTasty. Currently informational — no module reads them; host modules under `hosts/bigtasty/modules/` import unconditionally. Flags reserved for a future host that wants a partial server stack. |

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
| `overlays.nix` | catppuccin-vsc, ensemblr, and the local overlays (mpv-mpris, openldap, vapor-kde, duckstation, motrix, bambu-studio, periphery, solaar) |
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
| `services-media.nix` | jellyfin, uptime-kuma, *arr stack (sonarr/radarr/lidarr/prowlarr/seerr), flaresolverr (Prowlarr Cloudflare proxy), `programs.chromium` |
| `services-web.nix` | nginx vhosts + ACME with Cloudflare DNS-01 |
| `services-cloudflare.nix` | `services.cloudflared` tunnel `CFD_MAIN_TUNNEL`, `services.cloudflare-dyndns` |
| `services-shares.nix` | `services.nfs.server`, Samba (workgroup WORKGROUP, MacSamba/fruit), samba-wsdd, netatalk, `systemd.services.sharesSync` (inotify → rsync) |
| `services-misc.nix` | gnupg agent |
| `virtualisation.nix` | Host `oci-containers`, transmission restart policy, `systemd.services.docker-networks` oneshot creating immich-/paperless-/nocodb-/infisical-network |
| `sops.nix` | sops secrets for env files referenced by docker containers + ACME |
| `services/` | Pre-extracted service modules: `immich`, `paperless`, `syncthing`, `sotf-server`, `n8n`, `nocodb`, `vaultwarden`, `infisical` |

## Flake inputs

| Input | Purpose |
|---|---|
| `nixpkgs` | nixos-unstable — default package set |
| `nixpkgs-stable` | nixos-25.05 — calibre, Obsidian, prisma-engines |
| `home-manager` | Wired as NixOS module on both hosts |
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
4. Add `<Name>` to the `ALL_HOSTS` arrays in `update_system`, `rebuild_system` and `clean_system` in [hosts/whopper/home/scripts/default.nix](hosts/whopper/home/scripts/default.nix) so `all` picks it up.

## Deploy

`rebuild_system` is host-aware. It lives in Whopper's HM scripts ([hosts/whopper/home/scripts/default.nix](hosts/whopper/home/scripts/default.nix)); BigTasty does not install it. It runs locally if the arg matches the current host; otherwise it SSHes to `psoldunov@<host>` and builds on the target (`--target-host`, `--build-host`, `--sudo`).

```fish
rebuild_system                # rebuild current host locally
rebuild_system Whopper        # explicit local
rebuild_system BigTasty       # remote build + activate via SSH agent
rebuild_system all            # Whopper then BigTasty
update_system [host|all]      # same shape; runs `nix flake update` + update_claude_code, update_duckstation, update_motrix first, switches with --upgrade-all
clean_system [host|all]       # nix-collect-garbage -d (sudo + user) + docker image prune
```

`rebuild_system` and `update_system` always work in `~/.nixfiles`. They run `git add -A` first and commit everything after a successful switch (`rebuild commit <date>` / `update commit <date>`).

Inside an Ensemblr worktree, use the run scripts in [.ensemblr/settings.toml](.ensemblr/settings.toml) instead. They target the worktree's flake (`.#<Host>`) and leave staging and committing to you.

When deploying from a machine that is not managed by this flake, the helper scripts
and `nixos-rebuild` may not exist on `$PATH`. Use the full command from a checkout
of this repo:

```sh
nix run nixpkgs#nixos-rebuild -- switch --flake .#BigTasty --target-host psoldunov@bigtasty --build-host psoldunov@bigtasty --sudo --show-trace
```

Use `dry-activate` instead of `switch` for a remote activation preview.

### Silent remote sudo

`rebuild_system BigTasty` runs without prompting because:

1. Whopper's [hosts/whopper/home/ssh.nix](hosts/whopper/home/ssh.nix) `bigtasty` host block: `ForwardAgent = true`.
2. BigTasty's [networking.nix](hosts/bigtasty/modules/networking.nix) enables `security.pam.sshAgentAuth` and adds `security.pam.services.sudo.sshAgentAuth = true`.
3. BigTasty sudo: `Defaults env_keep += "SSH_AUTH_SOCK"`.
4. The forwarded agent's key matches `/etc/ssh/authorized_keys.d/psoldunov` declared in [users.nix](hosts/bigtasty/modules/users.nix).

Bootstrap: if the very first deploy needs a sudo password (no NOPASSWD yet on a fresh box), drop `%wheel ALL=(ALL) NOPASSWD: ALL` into `/etc/sudoers.d/99-bootstrap` once, deploy, then remove.

## Secrets

- **Backend**: sops-nix + age. Primary recipient declared in [.sops.yaml](.sops.yaml).
- **Files**: `secrets/whopper.yaml`, `secrets/bigtasty.yaml`, `secrets/shared.yaml`. Each host pins its own `sops.defaultSopsFile` (`hosts/<host>/modules/sops.nix` + its home module). Entries both hosts need point at `shared.yaml` with a per-secret `sopsFile`.
- **Age key path on each host**: `~/.config/sops/age/keys.txt`.

Notable secrets:

| Secret | Host | Consumer |
|---|---|---|
| `STEAM_API_KEY`, `STEAMGRIDDB_API_KEY` | Whopper system | `programs.steam.presence` |
| `SUNSHINE_WEB_PASSWORD` | Whopper system | Sunshine web UI login, written before each start |
| `SYNCTHING_GUI_PASSWORD` | both (system, `shared.yaml`) | `services.syncthing.guiPasswordFile` |
| `WIFI_PASSWORD` | BigTasty (system, `shared.yaml`) | wpa_supplicant `secretsFile`, rendered by a sops template (only while `networking.wireless` is enabled) |
| `SHELL_SECRETS` | both (user) | fish/bash init in shared `shell.nix`; shell-only env exports |
| `CLAUDE_SANITY_MCP_BEARER`, `N8N_ACCESS_TOKEN`, `NOCODB_API_KEY`, `PAPERLESS_API_KEY` | both (user, `shared.yaml`) | Claude Code MCP servers ([mcp.nix](modules/home/programs/claude-code/mcp.nix)) |
| `SPOTIFYD_PASSWORD` | Whopper (user) | spotifyd `password_cmd` |
| `CFD_MAIN_TUNNEL`, `CFDYNDNS_TOKEN`, `CF_DNS_CREDS` | BigTasty | cloudflared, cloudflare-dyndns, ACME DNS-01 |
| `SLSKD_ENV`, `JELLYPLEX_ENV`, `HOMARR_SETTINGS`, `IMMICH_SETTINGS`, ... | BigTasty | `virtualisation.oci-containers.containers.*.environmentFiles` |

### Editing

```fish
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops edit secrets/whopper.yaml
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops edit secrets/bigtasty.yaml
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops edit secrets/shared.yaml
```

On Whopper, `sops-code <file>` opens the same editor session in VS Code.

## Inspect

```fish
nix flake check --no-build
nix eval .#nixosConfigurations.Whopper.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.BigTasty.config.system.build.toplevel.drvPath
nixos-rebuild dry-activate --flake .#BigTasty --target-host psoldunov@bigtasty --sudo
```

## Conventions

- **`/modules` is shared-only.** Anything host-specific lives under `hosts/<host>/`. Shared modules hold the host-agnostic baseline; hosts append to lists and attrsets rather than redefine them.
- **`hostConfig` over `mkOption`.** No formal module options for now; flags threaded via `specialArgs`. Upgrade if/when a third host needs diverging settings.
- **Scripts on `$PATH`.** Everything in `hosts/whopper/home/scripts/` lands in `home.packages`, so other modules and shortcuts call scripts by bare name, not by Nix store path.
- **Closure isolation.** Shared modules that pull desktop-heavy deps (kitty, thunderbird, prisma-engines) must gate them behind `lib.optionalAttrs (hostConfig.role == "desktop")` — see [modules/home/shell/shell.nix](modules/home/shell/shell.nix) for the pattern.
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
