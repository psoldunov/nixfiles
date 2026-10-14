#!/usr/bin/env bash
# Switches BigMac to this checkout's flake from another host. The Ensemblr
# run scripts use it; rebuild_system and update_system do the same through
# modules/home/workstation/scripts.nix.
#
#   scripts/switch-bigmac.sh            switch
#   scripts/switch-bigmac.sh --update   switch, then update_bleeding_edge
#
# The flake and every input, the private ones included, are copied into the
# Mac's store first, so the Mac needs no GitHub token. Everything on the Mac
# runs in one ssh session: sudo asks for the password once, and a loop keeps
# that ticket fresh for darwin-rebuild, Homebrew's .pkg installs and
# update_bleeding_edge.
set -euo pipefail
cd "$(dirname "$0")/.."

target=psoldunov@bigmac
after=""
if [ "${1:-}" = "--update" ]; then
  after=" && /etc/profiles/per-user/psoldunov/bin/update_bleeding_edge"
fi

src="$(nix flake archive --json \
  --to "ssh-ng://$target?remote-program=/run/current-system/sw/bin/nix-daemon" \
  | jq -r .path)"

# POSIX sh for the Mac. LANG works around NixOS/nixpkgs#570561.
keep='sudo -v || exit 1; while true; do sudo -n true; sleep 50; done 2>/dev/null & k=$!; trap "kill $k 2>/dev/null" EXIT'
ssh -t "$target" "/bin/sh -c '$keep; export LANG=en_US.UTF-8; sudo /run/current-system/sw/bin/darwin-rebuild switch --flake $src#BigMac --show-trace$after'"
