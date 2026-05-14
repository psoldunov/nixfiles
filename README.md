# nixfiles

Personal NixOS + home-manager configuration for **Whopper**, an AMD GPU desktop running Hyprland on Wayland. Single-host today, structured to make adding more hosts trivial.

## Host: Whopper

| | |
|---|---|
| CPU | Intel (kvm-intel) |
| GPU | AMD Radeon (amdgpu, ROCm, gamescope) |
| Display | DP-1 @ 3840x2160@144 |
| Network | 10 Gbps NIC (`enp10s0`), static IP `10.24.24.5` |
| Filesystem | ext4 root + NFS mounts for media/files/games |
| Desktop | Hyprland + hypridle + hyprlock + AGS bar |
| Greeter | regreet (Catppuccin Mocha Peach) |
| Shell | fish |
| Secrets | sops-nix + age |

## Layout

```
.
├── flake.nix                  # Inputs + single call into lib/mkHost
├── flake.lock
├── lib/
│   └── mkHost.nix             # Thin nixosSystem wrapper; adding a host = one-line
├── hosts/
│   └── whopper/
│       ├── default.nix        # Imports ./hardware.nix + modules/nixos
│       ├── hardware.nix       # nixos-generate-config output
│       └── hostConfig.nix     # Per-host knobs (enableHyprland, ollamaDocker)
├── modules/
│   ├── nixos/                 # 15 focused NixOS modules — see "NixOS modules"
│   └── home/                  # Home-manager modules — see "Home-manager modules"
├── overlays/                  # Custom package overlays, applied in modules/nixos/overlays.nix
│   ├── hyprevents.nix         #   hyprevents from GitHub
│   ├── mpv-mpris.nix          #   mpv + mpris script
│   └── pedro-raccoon-plymouth.nix
└── secrets/
    └── secrets.yaml           # SOPS-encrypted (age)
```

## Flake inputs

All sourced in [flake.nix](flake.nix).

| Input | Purpose |
|---|---|
| `nixpkgs` | nixos-unstable — default package set |
| `nixpkgs-stable` | nixos-25.05 — used for Obsidian, Nextcloud client |
| `home-manager` | Wired as a NixOS module via `home-manager.nixosModules.home-manager` |
| `hyprland` | Upstream Hyprland flake (provides NixOS + HM modules) |
| `hyprland-plugins` | Optional plugin set (currently not instantiated) |
| `sops-nix` | NixOS + HM modules for sops-age secret management |
| `nix-gaming` | Pipewire low-latency + platform optimizations |
| `nix-flatpak` | Declarative Flatpak packages (Flatseal, SGDBoop) |
| `catppuccin` | Catppuccin theming module (Mocha/Peach) |
| `catppuccin-vsc` | VSCode Catppuccin extension overlay |
| `vscode-server` | nixos-vscode-server — makes VS Code Remote-SSH work |
| `zen-browser` | Zen browser package (added to `sharedModules`) |
| `apple-fonts` | SF Pro / SF Mono / NY font family |
| `ags` | AGS (Aylur's GTK Shell) — bar framework |

## Flake outputs

```nix
nixosConfigurations.Whopper = mkHost { system = "x86_64-linux"; modules = [ ... ]; specialArgs = { hostConfig = ...; ... }; }
formatter.x86_64-linux = alejandra
```

Everything flows through `lib/mkHost.nix`. To add a new host, drop a folder under `hosts/<name>/` and add one line to `flake.nix`:

```nix
nixosConfigurations.<name> = mkHost {
  system = "x86_64-linux";
  specialArgs = { ...; hostConfig = import ./hosts/<name>/hostConfig.nix; };
  modules = [ ./hosts/<name>/default.nix ... ];
};
```

## `hostConfig` — per-host knobs

Defined at [hosts/whopper/hostConfig.nix](hosts/whopper/hostConfig.nix) and threaded via `specialArgs`. Schema:

| Field | Type | Meaning |
|---|---|---|
| `enableHyprland` | bool | If `false`, disables Hyprland session and falls back to SDDM + Plasma6. Gates AGS, rofi, hypridle, pywal, GTK theming, blueman, etc. |
| `ollamaDocker` | bool | If `true`, runs Ollama as a rocm Docker container instead of the native `services.ollama` service. Adds a thin `ollama` wrapper script that execs into the container. |

Consume it in modules via the `hostConfig` argument (passed automatically via `specialArgs`).

## NixOS modules

Aggregator: [modules/nixos/default.nix](modules/nixos/default.nix). Each file below is a single-concern NixOS module.

| File | Purpose |
|---|---|
| [boot.nix](modules/nixos/boot.nix) | systemd-boot, Plymouth (`pedro-raccoon`), kernel params, initrd modules (`amdgpu`, `nfs`), swraid, extra kernel modules (`gasket`, `v4l2loopback`) |
| [desktop-environment.nix](modules/nixos/desktop-environment.nix) | Hyprland session, regreet greeter, flatpak, xdg mime (30+ defaults), GVFS, udisks2, tumbler, gnome-keyring, dconf |
| [fonts.nix](modules/nixos/fonts.nix) | Noto, Comic Neue, IBM Plex, Apple SF family, JetBrainsMono Nerd Font |
| [hardware.nix](modules/nixos/hardware.nix) | AMD graphics (mesa from hyprland's pinned nixpkgs), openrazer, logitech, sane, bluetooth, QMK + ZSA keyboard, i2c, HP printer ensurance |
| [locale.nix](modules/nixos/locale.nix) | `Asia/Nicosia`, `en_US.UTF-8` + regional overrides |
| [mounts.nix](modules/nixos/mounts.nix) | Local NVMe/SATA + 9 NFS mounts (Media, Files, Documents, Camera, Transmission, SLSKD, Paperless, Games) — all marked `x-gvfs-show` with icons |
| [networking.nix](modules/nixos/networking.nix) | Hostname, static IP, 30+ TCP/UDP firewall ports, openssh (key-only), avahi |
| [nix.nix](modules/nixos/nix.nix) | Nix settings, cachix substituters (nix-gaming, hyprland), experimental features |
| [overlays.nix](modules/nixos/overlays.nix) | Registers all top-level overlays |
| [packages.nix](modules/nixos/packages.nix) | `environment.systemPackages` (~120 pkgs), nano config, nix-ld, direnv/seahorse/1password/fish/steam/gamescope/gamemode, nixpkgs config (`allowUnfree`, `joypixels`), etc. |
| [security.nix](modules/nixos/security.nix) | polkit (custom ollama.service rule for psoldunov), rtkit, PAM with Yubico challenge-response + u2f for sudo/login, pki, gnupg agent |
| [services.nix](modules/nixos/services.nix) | Ollama, MySQL (mariadb), Syncthing (with SOPS password), Pipewire, Printing/CUPS, udev (yubikey + Apple Superdrive), dp-retrain systemd unit, ExpressVPN, vscode-server, ddccontrol |
| [sops.nix](modules/nixos/sops.nix) | sops-nix config, system-level secret declarations (`EXPRESSVPN_KEY`, `SYNCTHING_GUI_PASSWORD`) |
| [users.nix](modules/nixos/users.nix) | `psoldunov` user, groups, `system.stateVersion = "23.11"` |
| [virtualisation.nix](modules/nixos/virtualisation.nix) | Docker + libvirtd + containerd, SPICE USB redirection, 4 OCI containers (ollama-rocm, whisper-rocm, portainer-agent, watchtower), virt-manager |

## Home-manager modules

Aggregator: [modules/home/default.nix](modules/home/default.nix). Single-user (`psoldunov`).

### Core

| File | Purpose |
|---|---|
| [default.nix](modules/home/default.nix) | Imports all modules, catppuccin theming, `home.stateVersion = "23.11"` |
| [sops.nix](modules/home/sops.nix) | User-level SOPS config, secret declarations (`SHELL_SECRETS`; `SPOTIFYD_PASSWORD` is declared inside its own module) |
| [services.nix](modules/home/services.nix) | Nextcloud client (from `pkgs-stable`), gnome-keyring, nix-index, btop, htop, nemo-nextcloud extension |
| [packages.nix](modules/home/packages.nix) | `home.packages` — desktop apps (Slack, Plexamp, Spotify, Bruno, Obsidian, Anytype, etc.) |
| [ssh.nix](modules/home/ssh.nix) | SSH host config (github, gitlab, mynixos, thinkpad via cloudflared) |
| [dconf.nix](modules/home/dconf.nix) | Dark GNOME prefer-color-scheme, Catppuccin cursors |
| [scripts/default.nix](modules/home/scripts/default.nix) | All user shell scripts — see "Scripts" section |

### XDG

| File | Purpose |
|---|---|
| [xdg/desktop-entries.nix](modules/home/xdg/desktop-entries.nix) | 13 custom `.desktop` launchers (Spotify, LM Studio, webflow/openwebui/postman/memos app-mode shortcuts, figma-linux AppImage, VS Code nixfiles shortcuts for bigtasty/nugget, Clockify) |
| [xdg/portal.nix](modules/home/xdg/portal.nix) | `xdg-desktop-portal-gtk`, secret portal via gnome-keyring |

### Browser

| File | Purpose |
|---|---|
| [browser/chromium.nix](modules/home/browser/chromium.nix) | `programs.chromium` set to Brave, 16 extensions managed by ID |

### Shell

| File | Purpose |
|---|---|
| [shell/shell.nix](modules/home/shell/shell.nix) | fish (default), bash, starship, fzf, zoxide, atuin (sync), yazi, fastfetch |

### Dev

| File | Purpose |
|---|---|
| [dev/dev.nix](modules/home/dev/dev.nix) | Bun config (renamed from the legacy `dev/dev.nix`) |
| [dev/neovim.nix](modules/home/dev/neovim.nix) | Minimal neovim module (withNodeJs/Python3/Ruby) |
| [dev/projects.nix](modules/home/dev/projects.nix) | **Plain data file** (not a HM module) — list of projects consumed by the rofi project-manager keybind |
| [git/git.nix](modules/home/git/git.nix) | git config + `gh` CLI |

### Desktop / Hyprland

| File | Purpose |
|---|---|
| [desktop/hyprland.nix](modules/home/desktop/hyprland.nix) | `wayland.windowManager.hyprland` — monitors, input, exec-once, autoStart script |
| [desktop/hypr-modules/keybinds.nix](modules/home/desktop/hypr-modules/keybinds.nix) | Hyprland binds (MOD1–MOD4), rofi project manager shell script |
| [desktop/hypr-modules/windowrules.nix](modules/home/desktop/hypr-modules/windowrules.nix) | Window rules (new syntax only) |
| [desktop/hypridle.nix](modules/home/desktop/hypridle.nix) | hypridle + hyprlock config (Catppuccin palette inline — future split candidate) |
| [desktop/ags.nix](modules/home/desktop/ags.nix) | AGS bar launcher — source tree lives under [desktop/ags/](modules/home/desktop/ags/) (JS + SCSS) |
| [desktop/rofi.nix](modules/home/desktop/rofi.nix) | rofi drun config |
| [desktop/mako.nix](modules/home/desktop/mako.nix) | Notification daemon |
| [desktop/pywal.nix](modules/home/desktop/pywal.nix) | pywal templates for hyprland/waybar/wlogout |
| [desktop/gtk/default.nix](modules/home/desktop/gtk/default.nix) | Catppuccin GTK theme, Papirus icons, bookmarks |
| [desktop/qt/default.nix](modules/home/desktop/qt/default.nix) | Qt5/6 theming via qt5ct + qt6ct |

### Terminals / Programs

| File | Purpose |
|---|---|
| [programs/kitty.nix](modules/home/programs/kitty.nix) | Kitty config (primary terminal) |
| [programs/ghostty.nix](modules/home/programs/ghostty.nix) | Ghostty config (not imported in `default.nix` — available if you want to switch) |
| [programs/spotifyd.nix](modules/home/programs/spotifyd.nix) | Spotifyd daemon, password via SOPS `password_cmd` |
| [programs/vscode.nix](modules/home/programs/vscode.nix) | `programs.vscode.enable = true` — settings managed externally |

## Scripts

All scripts live in [modules/home/scripts/default.nix](modules/home/scripts/default.nix) as a proper HM module. They are exposed on `$PATH` via `home.packages`, so keybinds and other modules reference them by bare binary name (`exec, create_screenshot`) rather than Nix store paths.

### Always-on

`shadd`, `convert_all_to_mkv`, `convert_all_to_webp`, `convert_all_to_woff2`, `sops-code`, `kill_gamescope`, `update_system`, `rebuild_system`, `clean_system`, `make_timed_commit`, `restart_steam`

### Hyprland-only (gated on `hostConfig.enableHyprland`)

`restart_ags`, `idle_check`, `record_screen`, `grab_screen_text`, `create_screenshot`, `create_screenshot_area`, `brightness_control`, `start_static_wallpaper`, `start_video_wallpaper`, `fix_xdph`, `restart_xdg_desktop_portal`, `cycle_monitor_refresh_rate`

Several of these source `${config.sops.secrets.SHELL_SECRETS.path}` to pick up API keys (Zipline, OpenAI, etc).

## Overlays

Registered in [modules/nixos/overlays.nix](modules/nixos/overlays.nix). Each file is a plain `self: super: { ... }` overlay.

| Overlay | What it does |
|---|---|
| `inputs.catppuccin-vsc.overlays.default` | Adds `catppuccin-vsc` theme extension |
| [hyprevents.nix](overlays/hyprevents.nix) | Custom derivation for [vilari-mickopf/hyprevents](https://github.com/vilari-mickopf/hyprevents) |
| [pedro-raccoon-plymouth.nix](overlays/pedro-raccoon-plymouth.nix) | Custom Plymouth theme derivation |
| [mpv-mpris.nix](overlays/mpv-mpris.nix) | Rebuilds `mpv` with the `mpris` lua script bundled |

`hyprprop` is used by keybinds / shell abbreviations but comes from nixpkgs directly — **no overlay needed**.

## Secrets

- **Backend**: sops-nix + age
- **Encrypted file**: [secrets/secrets.yaml](secrets/secrets.yaml)
- **Age key path**: `~/.config/sops/age/keys.txt` (defined in [.sops.yaml](.sops.yaml))
- **System secrets** (declared in [modules/nixos/sops.nix](modules/nixos/sops.nix)):
  - `EXPRESSVPN_KEY` — owned by `psoldunov`
  - `SYNCTHING_GUI_PASSWORD` — owned by `psoldunov`, consumed via `services.syncthing.guiPasswordFile`
- **User secrets** (declared in [modules/home/sops.nix](modules/home/sops.nix) and per-module):
  - `SHELL_SECRETS` — shell env var dump sourced by scripts that upload to Zipline
  - `SPOTIFYD_PASSWORD` — declared in [programs/spotifyd.nix](modules/home/programs/spotifyd.nix), consumed via `password_cmd`

### Editing secrets

```fish
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops edit secrets/secrets.yaml
# or, non-interactive:
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops set secrets/secrets.yaml '["NEW_KEY"]' '"value"'
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops unset secrets/secrets.yaml '["OLD_KEY"]'
```

## Common workflows

### Rebuild

```fish
# Build only (no activation)
nixos-rebuild build --flake ~/.nixfiles#Whopper

# Activate and switch
sudo nixos-rebuild switch --flake ~/.nixfiles#Whopper

# Wrapper script (commits + switches, available on $PATH)
rebuild_system
```

### Update

```fish
# Bump all flake inputs + switch
sudo nix flake update --flake ~/.nixfiles
sudo nixos-rebuild switch --flake ~/.nixfiles#Whopper

# Wrapper that also commits
update_system
```

### Garbage collection

```fish
clean_system   # sudo nix-collect-garbage -d && nix-collect-garbage -d
```

### Format

```fish
nix run nixpkgs#alejandra -- flake.nix lib hosts modules overlays
```

### Inspect config

```fish
# Functional equivalence / introspection
nix eval .#nixosConfigurations.Whopper.config.networking.hostName
nix eval --json .#nixosConfigurations.Whopper.config.environment.systemPackages | jq length
nix eval .#nixosConfigurations.Whopper.config.services.syncthing.enable

# Dry-activation (shows what would change without touching the system)
sudo nixos-rebuild dry-activate --flake ~/.nixfiles#Whopper
```

## Adding a new host

1. Create `hosts/<name>/`:
   - `hardware.nix` — output of `nixos-generate-config --show-hardware-config > hosts/<name>/hardware.nix`
   - `hostConfig.nix` — per-host toggles (see `hostConfig` schema above)
   - `default.nix` — imports `./hardware.nix` and `../../modules/nixos` (plus any host-specific overrides)
2. Add one entry to `flake.nix`:
   ```nix
   nixosConfigurations.<name> = mkHost {
     system = "x86_64-linux";
     specialArgs = {
       inherit inputs outputs appleFonts pkgs-stable;
       hostConfig = import ./hosts/<name>/hostConfig.nix;
     };
     modules = [
       ./hosts/<name>/default.nix
       # shared external modules (nix-gaming, sops-nix, hyprland, etc.)
     ];
   };
   ```
3. For host-specific home-manager config, either override `home-manager.users.psoldunov` inside the new host's `default.nix` or add `hostConfig` flags that the existing HM modules consult.

## Conventions

- **No `options` declarations.** `hostConfig` is threaded via `specialArgs` instead of formal `mkOption`/`mkEnableOption`. Upgrade to module options only if and when a third host needs diverging settings.
- **Scripts belong on `$PATH`**, not as Nix store paths embedded in other files. Keybinds reference script binaries by bare name.
- **Immutable data imports** (like [dev/projects.nix](modules/home/dev/projects.nix)) are plain Nix files, not HM modules — they return an attrset and are consumed via `import`, not `imports`.
- **Assets live next to the module that uses them** — wallpaper, startup sounds, app icons under [desktop/assets/](modules/home/desktop/assets/).
- **Flake-visibility**: remember that `nix flake` only sees **git-tracked** files. After creating a new file, `git add` it before `nixos-rebuild build` or you'll see `path does not exist` errors.
- **Formatting**: alejandra. Run it before committing.

## Troubleshooting

### `path 'X' does not exist` during eval
You forgot to `git add` the new file. Flakes only see tracked files.

### `error: hash mismatch in fixed-output derivation`
An overlay or `fetchFromGitHub` has a stale hash. Either update the `sha256` or drop the overlay if the upstream package now exists in nixpkgs.

### `nixos-rebuild` fails with a hook error
If a pre-commit hook complains about destructive operations, it's likely the `block-rm-rf` hook in `~/.claude/hooks/`. Use `git rm -r --force <path>` (with `-r` as a separate flag) instead of `rm -rf`.

### Stale `home-manager` generation after editing a HM module
`home-manager` profiles update on `nixos-rebuild switch`. If something is still broken after switch, check:
```fish
systemctl --user status home-manager-psoldunov
journalctl --user -u home-manager-psoldunov -b
```

## History

The repo was refactored from a monolithic `nixos/configuration.nix` (1069 lines) + `home-manager/home.nix` (445 lines) into the current layout over a 9-phase plan. Highlights:

- Every NixOS concern now lives in its own module under `modules/nixos/`.
- Home-manager is split by UX surface (browser, xdg, shell, dev, desktop, scripts).
- Overlays moved to top-level `overlays/` so they're reusable by both NixOS and HM contexts.
- Syncthing + Spotifyd credentials migrated from plaintext-in-git to SOPS.
- Scripts became a proper HM module (previously a raw attrset double-imported in two places). `brightness_control` is now actually on `$PATH`.
- `globalSettings` → `hostConfig`, extracted to per-host file.
- ~600 lines of dead/commented code removed (legacy windowrules, commented vscode settings, commented fastfetch config, the unused `ncmpcpp` module).
