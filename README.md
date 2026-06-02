# nixfiles

Personal NixOS + home-manager configuration. Multi-host flake, single source of truth.

| Host | Role | Hardware |
|---|---|---|
| **Whopper** | Desktop | AMD GPU (gamescope, ROCm), DP-1 @ 3840x2160@144, 10 Gbps NIC, Hyprland on Wayland |
| **BigTasty** | Home server | Intel iGPU (Quick Sync), mdadm RAID, static IP `10.24.24.2`, NFS + Samba + Netatalk exports, nginx vhosts behind Cloudflare DNS-01 |

Both hosts share a small set of home-manager modules (`shell`, `git`, Claude Code config). Everything else is host-scoped.

## Layout

```
.
├── flake.nix                       # Inputs + nixosConfigurations.{Whopper,BigTasty}
├── lib/
│   └── mkHost.nix                  # Thin nixpkgs.lib.nixosSystem wrapper
├── modules/                        # SHARED ONLY
│   └── home/
│       ├── default.nix             # Imports all shared modules
│       ├── git/git.nix             # git + gh config
│       ├── shell/shell.nix         # fish/bash/starship/atuin/zoxide/yazi (desktop bits gated)
│       └── programs/claude-code/   # Declarative Claude Code (agents/hooks/skills/MCP/settings)
├── hosts/
│   ├── whopper/
│   │   ├── default.nix             # Imports ./hardware.nix + ./modules
│   │   ├── hardware.nix
│   │   ├── hostConfig.nix          # role=desktop + server flags=false
│   │   ├── modules/                # NixOS modules (15 files)
│   │   └── home/                   # Whopper-only HM (desktop, dev, services, scripts, ...)
│   └── bigtasty/
│       ├── default.nix
│       ├── hardware.nix
│       ├── hostConfig.nix          # role=server + server flags=true
│       ├── modules/                # NixOS modules — see "BigTasty modules"
│       │   └── services/           # Pre-extracted service stacks
│       └── home/home.nix           # Imports shared + minimal server bits
├── overlays/                       # Custom nixpkgs overlays (Whopper-only currently)
└── secrets/
    ├── whopper.yaml                # SOPS-encrypted (age, primary recipient)
    └── bigtasty.yaml
```

## Hosts

### Whopper (desktop)

| | |
|---|---|
| GPU | AMD Radeon (amdgpu, ROCm, gamescope, HDR) |
| Display | DP-1 @ 3840x2160@144 |
| Network | 10 Gbps NIC (`enp10s0`), static IP `10.24.24.5` |
| Filesystem | ext4 root + 9 NFS mounts (Media, Files, Documents, Camera, Transmission, SLSKD, Paperless, Games) |
| Desktop | Hyprland + hypridle + hyprlock + AGS bar |
| Auth | PAM Yubikey challenge-response + u2f for sudo/login |
| Steam | `programs.steam` (millennium) + steam-presence wired to `STEAM_API_KEY` sops secret |

### BigTasty (server)

| | |
|---|---|
| GPU | Intel iGPU (intel-media-driver, Quick Sync, VAAPI) |
| Storage | mdadm RAID array mounted at `/RAID`, NFS mounts `/mnt/{Media,Backup,Games}` |
| Network | static IP `10.24.24.2`, openssh (`AllowUsers psoldunov`) |
| Services | jellyfin, sonarr/radarr/lidarr/prowlarr/seerr, uptime-kuma, immich, paperless, vaultwarden, infisical, nocodb, n8n, karakeep, syncthing, sotf-server |
| Reverse proxy | nginx vhosts with Cloudflare DNS-01 ACME for `*.theswisscheese.com` |
| Tunnels | `services.cloudflared` for `search.theswisscheese.com`, `services.cloudflare-dyndns` syncing DNS records |
| Docker | `oci-containers`: jellyplex-watched, slskd, transmission, homeassistant, portainer, homarr, watchtower, searxng. Networks created by `systemd-services.docker-networks` (After=docker.service) |
| File sharing | `services.nfs.server` exports `/export/{transmission,slskd,Paperless,Files,Documents}`, Samba/samba-wsdd + Netatalk for AFP |
| Passwordless sudo | `pam_ssh_agent_auth` checks forwarded SSH agent against `/etc/ssh/authorized_keys.d/psoldunov` |

## `hostConfig`

Per-host knobs threaded via `specialArgs`. Shared schema in [hosts/whopper/hostConfig.nix](hosts/whopper/hostConfig.nix) and [hosts/bigtasty/hostConfig.nix](hosts/bigtasty/hostConfig.nix):

| Field | Type | Meaning |
|---|---|---|
| `role` | `"desktop" \| "server"` | Broad-stroke gate. `modules/home/shell/shell.nix` uses it to omit desktop-only env vars (kitty/thunderbird/prisma) and fish functions (`wkill`, `resetDE`) on servers. |
| `enableHyprland` | bool | Desktop session toggle (disables SDDM/Plasma6 fallback, gates AGS/rofi/hypridle/pywal/GTK theming) |
| `ollamaDocker` | bool | Run Ollama as a rocm container instead of native `services.ollama` |
| `enableRaid`, `enableNfsServer`, `enableSambaShares`, `enableNetatalk`, `enableMediaStack`, `enableArrStack`, `enableNginxVhosts`, `enableCloudflareTunnels`, `enableDyndns`, `enableDockerOci` | bool | Server-side feature flags. All `false` on Whopper, `true` on BigTasty. Currently informational — host modules under `hosts/bigtasty/modules/` import unconditionally; flags reserved for future host that wants partial server stack. |

## BigTasty modules

[hosts/bigtasty/modules/default.nix](hosts/bigtasty/modules/default.nix) imports:

| File | Purpose |
|---|---|
| `boot.nix` | systemd-boot, swraid, blacklisted nvidia/nouveau, kernel sysctl |
| `networking.nix` | hostname, static IP, firewall ports, openssh (`PrintMotd=false`, `PrintLastLog=false`), `pam_ssh_agent_auth`, sudo `env_keep SSH_AUTH_SOCK` |
| `hardware.nix` | intel-media-driver, intel-gpu-tools, fwupd, cachefilesd (`/RAID/cachefilesd`), nbd.server (cdrom), udev (Apple Superdrive), powertop, mdmonitor |
| `filesystems.nix` | `/RAID` ext4, NFS mounts, bind mounts for `/export/*` |
| `users.nix` | `psoldunov` (wheel/docker/libvirtd), `cloudflared` system user, declarative `openssh.authorizedKeys.keys` |
| `nix-locale.nix` | nix settings (`trusted-users = ["psoldunov"]`), `nixpkgs.config` (allowUnfree/Insecure/Broken), locale, time, programs.nix-ld |
| `packages.nix` | server-side `environment.systemPackages` + local `update_system`/`clean_system`/`rebuild_system` scripts |
| `services-media.nix` | jellyfin, uptime-kuma, *arr stack (sonarr/radarr/lidarr/prowlarr/seerr), `programs.chromium` |
| `services-web.nix` | nginx vhosts + ACME with Cloudflare DNS-01 |
| `services-cloudflare.nix` | `services.cloudflared` tunnel `CFD_MAIN_TUNNEL`, `services.cloudflare-dyndns` |
| `services-shares.nix` | `services.nfs.server`, Samba (workgroup WORKGROUP, MacSamba/fruit), samba-wsdd, netatalk, `systemd.services.sharesSync` (inotify → rsync) |
| `services-misc.nix` | fish, mtr, gnupg.agent, iperf3, programs.git |
| `virtualisation.nix` | docker + libvirtd + containerd, `oci-containers`, `systemd.services.docker-networks` oneshot creating immich-/paperless-/nocodb-/infisical-network |
| `sops.nix` | sops secrets for env files referenced by docker containers + ACME |
| `services/` | Pre-extracted service modules: `immich`, `paperless`, `karakeep`, `syncthing`, `sotf-server`, `n8n`, `nocodb`, `vaultwarden`, `infisical` |

## Whopper modules

Aggregator: [hosts/whopper/modules/default.nix](hosts/whopper/modules/default.nix). Same 15-file split as the historical `modules/nixos/` layout — see git history for the unchanged file list (`boot`, `desktop-environment`, `fonts`, `hardware`, `locale`, `mounts`, `networking`, `nix`, `overlays`, `packages`, `security`, `services`, `sops`, `users`, `virtualisation`). Whopper's `packages.nix` imports `inputs.steam-presence.nixosModules.steam-presence`.

## Flake inputs

| Input | Purpose |
|---|---|
| `nixpkgs` | nixos-unstable — default package set |
| `nixpkgs-stable` | nixos-25.05 — Obsidian, Nextcloud client, prisma-engines |
| `home-manager` | Wired as NixOS module on both hosts |
| `hyprland`, `hyprland-plugins` | Whopper desktop session |
| `sops-nix` | NixOS + HM secret management |
| `nix-gaming` | Whopper pipewire low-latency + platform-optimizations |
| `nix-flatpak` | Whopper Flatpak declarations |
| `catppuccin`, `catppuccin-vsc` | Whopper theming |
| `vscode-server` | Both hosts — VS Code Remote-SSH support |
| `zen-browser`, `apple-fonts`, `ags`, `millennium` | Whopper |
| `steam-presence` | Whopper Steam Discord presence |
| `context-mode`, `caveman` | Claude Code plugin sources |

## Adding a new host

1. `mkdir hosts/<name>` and create `hardware.nix` (from `nixos-generate-config --show-hardware-config`), `hostConfig.nix`, `default.nix`.
2. Add one entry to [flake.nix](flake.nix):
   ```nix
   nixosConfigurations.<Name> = mkHost {
     system = "x86_64-linux";
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
           users.psoldunov = import ./hosts/<name>/home/home.nix;
           sharedModules = [ sops-nix.homeManagerModules.sops ];
         };
       }
     ];
   };
   ```
3. Add `<Name>` to the `ALL_HOSTS` array in [hosts/whopper/home/scripts/default.nix](hosts/whopper/home/scripts/default.nix) so `rebuild_system all` picks it up.

## Deploy

`rebuild_system` is host-aware. Lives in Whopper's HM scripts ([hosts/whopper/home/scripts/default.nix](hosts/whopper/home/scripts/default.nix)). Runs locally if the arg matches the current host; otherwise SSHes to `psoldunov@<host>` and builds on the target (`--target-host`, `--build-host`, `--sudo`).

```fish
rebuild_system                # rebuild current host locally
rebuild_system Whopper        # explicit local
rebuild_system BigTasty       # remote build + activate via SSH agent
rebuild_system all            # Whopper then BigTasty
update_system [host|all]      # same shape, runs `nix flake update` first
clean_system                  # nix-collect-garbage -d (sudo + user)
```

When deploying from a machine that is not managed by this flake, the helper scripts
and `nixos-rebuild` may not exist on `$PATH`. Use the full command from a checkout
of this repo:

```sh
nix run nixpkgs#nixos-rebuild -- switch --flake .#BigTasty --target-host psoldunov@bigtasty --build-host psoldunov@bigtasty --sudo --show-trace
```

Use `dry-activate` instead of `switch` for a remote activation preview.

### Silent remote sudo

`rebuild_system BigTasty` runs without prompting because:

1. Whopper's [modules/home/ssh.nix](hosts/whopper/home/ssh.nix) bigtasty matchBlock: `forwardAgent = true`.
2. BigTasty's [networking.nix](hosts/bigtasty/modules/networking.nix) enables `security.pam.sshAgentAuth` and adds `security.pam.services.sudo.sshAgentAuth = true`.
3. BigTasty sudo: `Defaults env_keep += "SSH_AUTH_SOCK"`.
4. The forwarded agent's key matches `/etc/ssh/authorized_keys.d/psoldunov` declared in [users.nix](hosts/bigtasty/modules/users.nix).

Bootstrap: if the very first deploy needs a sudo password (no NOPASSWD yet on a fresh box), drop `%wheel ALL=(ALL) NOPASSWD: ALL` into `/etc/sudoers.d/99-bootstrap` once, deploy, then remove.

## Secrets

- **Backend**: sops-nix + age. Primary recipient declared in [.sops.yaml](.sops.yaml).
- **Files**: `secrets/whopper.yaml`, `secrets/bigtasty.yaml`. Each host pins its own `sops.defaultSopsFile` per-host (`hosts/<host>/modules/sops.nix` + `hosts/<host>/home/...`).
- **Age key path on each host**: `~/.config/sops/age/keys.txt`.

Notable secrets:

| Secret | Host | Consumer |
|---|---|---|
| `EXPRESSVPN_KEY`, `SYNCTHING_GUI_PASSWORD`, `STEAM_API_KEY` | Whopper system | services.syncthing.guiPasswordFile, programs.steam.presence.steamApiKeyFile |
| `SHELL_SECRETS` | both (user) | `shellInitLast` in shared shell.nix; populates Zipline/OpenAI tokens |
| `SPOTIFYD_PASSWORD` | Whopper (user) | spotifyd `password_cmd` |
| `CFD_MAIN_TUNNEL`, `CFDYNDNS_TOKEN`, `CF_DNS_CREDS` | BigTasty | cloudflared, cloudflare-dyndns, ACME DNS-01 |
| `SLSKD_ENV`, `JELLYPLEX_ENV`, `HOMARR_SETTINGS`, `IMMICH_SETTINGS`, ... | BigTasty | `virtualisation.oci-containers.containers.*.environmentFiles` |

### Editing

```fish
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops edit secrets/whopper.yaml
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops edit secrets/bigtasty.yaml
```

## Inspect

```fish
nix flake check --no-build
nix eval .#nixosConfigurations.Whopper.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.BigTasty.config.system.build.toplevel.drvPath
sudo nixos-rebuild dry-activate --flake ~/.nixfiles#BigTasty --target-host psoldunov@bigtasty
```

## Conventions

- **`/modules` is shared-only.** Anything host-specific lives under `hosts/<host>/`.
- **`hostConfig` over `mkOption`.** No formal module options for now; flags threaded via `specialArgs`. Upgrade if/when a third host needs diverging settings.
- **Scripts on `$PATH`.** Keybinds and other modules reference bare binaries (`exec, create_screenshot`), not Nix store paths.
- **Closure isolation.** Shared modules that pull desktop-heavy deps (kitty, thunderbird, prisma-engines, supabase-cli) must gate them behind `lib.optionalAttrs (hostConfig.role == "desktop")` — see [modules/home/shell/shell.nix](modules/home/shell/shell.nix) for the pattern.
- **Flake visibility.** `nix flake` only sees git-tracked files. `git add` new files before `nixos-rebuild build`.
- **Formatting**: alejandra. `nix run nixpkgs#alejandra -- flake.nix lib hosts modules overlays`.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `path 'X' does not exist` during eval | New file not `git add`ed |
| Sudo password prompted on remote deploy | `pam_ssh_agent_auth` not yet active (first deploy on a fresh box); use bootstrap sudoers.d |
| `error: cannot add path ... because it lacks a signature by a trusted key` | Target host's `nix.settings.trusted-users` doesn't include `psoldunov`; or omit `--build-host` and let target build locally |
| Docker container activation fails on first switch | `systemd-services.docker-networks` is After=docker.service — if docker.service stopped during activation, networks aren't there yet; retry deploy |
| Stale `home-manager` generation | `systemctl --user status home-manager-psoldunov && journalctl --user -u home-manager-psoldunov -b` |

## History

The repo started as a single-host Whopper monolith (`modules/nixos/configuration.nix` ~1000 lines + `home-manager/home.nix` ~445 lines), got refactored into per-concern modules, then merged with the `psoldunov/nixfiles-server` repo to become multi-host. BigTasty's old 700-line `configuration.nix` was decomposed into focused modules under `hosts/bigtasty/modules/` during the merge.
