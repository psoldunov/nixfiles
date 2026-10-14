#!/usr/bin/env bash
# First nix-darwin switch on BigMac. Later switches go through
# `rebuild_system BigMac` (or `rebuild_system` on the Mac itself).
#
# Order:
#   1. On the Mac: sudo /nix/nix-installer uninstall
#      (removes Determinate Nix; Homebrew and its apps are untouched)
#   2. On the Mac: sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)
#      (upstream Nix, multi-user)
#   3. On Whopper, in a checkout of this repo: scripts/bootstrap-bigmac.sh
#
# Step 3 runs everything on the Mac over `ssh -t`, so sudo asks for the Mac's
# password there. On the Mac it:
#   - lets psoldunov copy store paths into the Mac's Nix (trusted-users),
#   - copies this flake and all its inputs over, private ones included, so
#     the Mac needs no GitHub token for the first build,
#   - backs up every file the switch replaces to ~/pre-nix-backup-<date>.tar.gz,
#   - moves ~/.claude/settings.json aside, so Claude Code's settings start
#     from settings.nix instead of merging with the old file,
#   - moves the /etc files nix-darwin takes over to <file>.before-nix-darwin,
#   - builds and activates darwinConfigurations.BigMac.
#
# hosts/bigmac/modules/homebrew.nix sets Homebrew cleanup to "uninstall", so
# the switch removes every formula and cask it doesn't list. For a fresh Mac
# with an existing Homebrew setup, set it to "none" for the first switch.
set -euo pipefail

target=psoldunov@bigmac
nixbin=/nix/var/nix/profiles/default/bin
nixcmd=("$nixbin/nix" --extra-experimental-features "nix-command flakes")

on_mac() {
  local src="$1"

  if [ -e /nix/receipt.json ]; then
    echo "Determinate Nix is still installed (/nix/receipt.json)." >&2
    echo "Run 'sudo /nix/nix-installer uninstall', install upstream Nix, then rerun." >&2
    exit 1
  fi

  # darwin-rebuild and the activation scripts are nixpkgs bash, which can
  # crash on macOS 27 with no locale set (NixOS/nixpkgs#570561).
  export LANG="${LANG:-en_US.UTF-8}"

  # Ask for the password now and keep sudo's timestamp fresh, so the steps
  # after the long build don't stop on a second prompt.
  sudo -v
  while true; do
    sudo -n true
    sleep 50
  done 2>/dev/null &
  # Expanded now: the local is gone by the time the EXIT trap runs.
  # shellcheck disable=SC2064
  trap "kill $! 2>/dev/null" EXIT

  local backup
  backup="$HOME/pre-nix-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
  local paths=(
    .ssh .gitconfig .zshrc .zprofile .bashrc .bash_profile .profile
    .claude.json .claude/settings.json .claude/settings.local.json
    .claude/CLAUDE.md .claude/agents .claude/rules .claude/skills .claude/hooks
    .pi/agent/settings.json .pi/agent/extensions .pi/agent/AGENTS.md
    .config/fish .config/starship.toml .config/atuin .config/gh .config/git
    .config/lazygit .config/yazi .config/btop .config/htop .config/direnv
    .config/mise .config/fastfetch
  )
  local present=()
  for p in "${paths[@]}"; do
    if [ -e "$HOME/$p" ]; then present+=("$p"); fi
  done
  if [ "${#present[@]}" -gt 0 ]; then
    (umask 077 && tar -czf "$backup" -C "$HOME" "${present[@]}")
    echo "Backed up ${#present[@]} paths to $backup"
  fi

  if [ -f "$HOME/.claude/settings.json" ]; then
    # A rerun keeps the first run's copy.
    local aside="$HOME/.claude/settings.json.pre-nix"
    if [ -e "$aside" ]; then aside="$aside-$(date +%Y%m%d-%H%M%S)"; fi
    mv "$HOME/.claude/settings.json" "$aside"
    echo "Moved ~/.claude/settings.json to $aside"
  fi

  echo "Building darwinConfigurations.BigMac (first run downloads a lot)..."
  local sys
  sys="$("${nixcmd[@]}" build --keep-going --no-link --print-out-paths "$src#darwinConfigurations.BigMac.system")"

  for f in /etc/nix/nix.conf /etc/bashrc /etc/zshrc /etc/shells; do
    if [ -f "$f" ] && [ ! -L "$f" ]; then
      sudo mv "$f" "$f.before-nix-darwin"
      echo "Moved $f to $f.before-nix-darwin"
    fi
  done

  sudo "$sys/sw/bin/darwin-rebuild" switch --flake "$src#BigMac"
  echo "BigMac switched. Open a new terminal: the login shell is now Nix's fish."
}

if [ "${1:-}" = "--on-mac" ]; then
  on_mac "$2"
  exit 0
fi

cd "$(dirname "$0")/.."

echo "== Trusting psoldunov in the Mac's Nix daemon"
ssh -t "$target" "sudo /bin/sh -c 'grep -q \"^trusted-users = root psoldunov\" /etc/nix/nix.conf || echo \"trusted-users = root psoldunov\" >> /etc/nix/nix.conf; launchctl kickstart -k system/org.nixos.nix-daemon'"

# The Mac's own age key is not a recipient in .sops.yaml, so append the
# primary identity (the first key there) to its keys.txt. The secret goes
# through stdin, never argv.
echo "== Giving the Mac the sops age identity"
primary="$(grep -o 'age1[0-9a-z]*' .sops.yaml | head -n1)"
identity=""
while IFS= read -r line; do
  case "$line" in
    AGE-SECRET-KEY-*)
      if [ "$(printf '%s\n' "$line" | nix shell nixpkgs#age -c age-keygen -y)" = "$primary" ]; then
        identity="$line"
      fi
      ;;
  esac
done < "$HOME/.config/sops/age/keys.txt"
if [ -z "$identity" ]; then
  echo "No identity for $primary in ~/.config/sops/age/keys.txt" >&2
  exit 1
fi
if printf '%s\n' "$identity" | ssh "$target" "/bin/sh -c 'grep -qxFf /dev/stdin ~/.config/sops/age/keys.txt'"; then
  echo "The Mac already has it."
else
  printf '# public key: %s\n%s\n' "$primary" "$identity" \
    | ssh "$target" "/bin/sh -c 'mkdir -p ~/.config/sops/age && cat >> ~/.config/sops/age/keys.txt && chmod 600 ~/.config/sops/age/keys.txt'"
  echo "Appended it to the Mac's ~/.config/sops/age/keys.txt"
fi

echo "== Copying the flake and its inputs to the Mac"
src="$(nix flake archive --json --to "ssh-ng://$target?remote-program=$nixbin/nix-daemon" | jq -r .path)"
echo "Flake source on the Mac: $src"

echo "== Switching the Mac"
ssh -t "$target" "/bin/bash $src/scripts/bootstrap-bigmac.sh --on-mac $src"
