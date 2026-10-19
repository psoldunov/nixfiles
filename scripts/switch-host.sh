#!/usr/bin/env bash
# Switches a host to this checkout's flake, from whichever host runs it. The
# Ensemblr run scripts use it; rebuild_system and update_system do the same
# through switch_host in modules/home/workstation/scripts.nix, and pick the
# route the same way:
#
# - the host running it: nixos-rebuild or darwin-rebuild, locally;
# - NixOS from NixOS: nixos-rebuild --target-host --build-host;
# - macOS on either end, which has no nixos-rebuild: the flake and every
#   input, the private ones included, are copied into the target's store, and
#   the target builds and activates it in one ssh session. The target needs
#   no GitHub token, and sudo asks for its password once.
#
#   scripts/switch-host.sh <host>               switch
#   scripts/switch-host.sh <host> --update      switch, then update_bleeding_edge on a Mac
#   scripts/switch-host.sh <host> --if-online   skip, with a warning and exit 0, when
#                                               the host does not answer (the -all
#                                               scripts use it for the laptop and the HTPC)
set -euo pipefail
cd "$(dirname "$0")/.."

usage="usage: scripts/switch-host.sh <Whopper|BigTasty|BigKing|ShackStack|PiHome|BigMac|MacFlurry> [--update] [--if-online]"
host="${1:?$usage}"
shift
declare -A KIND=([Whopper]=nixos [BigTasty]=nixos [BigKing]=nixos [ShackStack]=nixos [PiHome]=nixos [BigMac]=darwin [MacFlurry]=darwin)
kind="${KIND[$host]:-}"
if [ -z "$kind" ]; then
  echo "$usage" >&2
  exit 1
fi
want_update=false
if_online=false
for arg in "$@"; do
  case "$arg" in
    --update) want_update=true ;;
    --if-online) if_online=true ;;
    *)
      echo "$usage" >&2
      exit 1
      ;;
  esac
done
local_kind=nixos
if [ "$(uname -s)" = Darwin ]; then
  local_kind=darwin
fi
# The ssh config (modules/home/workstation/ssh.nix) names each host in
# lower case.
target="psoldunov@${host,,}"
update=""
if [ "$want_update" = true ] && [ "$kind" = darwin ]; then
  update=/etc/profiles/per-user/psoldunov/bin/update_bleeding_edge
fi
is_local=false
if [ "$(hostname -s | tr '[:upper:]' '[:lower:]')" = "${host,,}" ]; then
  is_local=true
fi

# Same check as `reachable` in modules/home/workstation/scripts.nix: ssh gets
# in within a few seconds without prompting.
if [ "$if_online" = true ] && [ "$is_local" = false ] \
  && ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$target" true >/dev/null 2>&1; then
  echo "switch-host: $host is not reachable (asleep or away); skipping it." >&2
  exit 0
fi

if [ "$is_local" = true ]; then
  if [ "$kind" = darwin ]; then
    # Keep sudo's ticket fresh for Homebrew's .pkg installs during
    # activation and for update_bleeding_edge.
    sudo -v
    while true; do sudo -n true; sleep 50; done 2>/dev/null &
    keepalive=$!
    trap 'kill "$keepalive" 2>/dev/null' EXIT
    sudo /run/current-system/sw/bin/darwin-rebuild switch --flake ".#$host" --show-trace
    if [ -n "$update" ]; then
      "$update"
    fi
  else
    # Builds run as the user; --sudo elevates only activation.
    nixos-rebuild switch --flake ".#$host" --sudo --show-trace
  fi
elif [ "$kind" = nixos ] && [ "$local_kind" = nixos ]; then
  nixos-rebuild switch --flake ".#$host" --target-host "$target" --build-host "$target" --sudo --show-trace
else
  src="$(nix flake archive --json \
    --to "ssh-ng://$target?remote-program=/run/current-system/sw/bin/nix-daemon" \
    | jq -r .path)"
  tty=-T
  if [ -t 0 ]; then
    tty=-t
  fi
  # POSIX sh on the target. LANG works around NixOS/nixpkgs#570561.
  keep='sudo -v || exit 1; while true; do sudo -n true; sleep 50; done 2>/dev/null & k=$!; trap "kill $k 2>/dev/null" EXIT'
  after="${update:+ && $update}"
  ssh "$tty" "$target" "/bin/sh -c '$keep; export LANG=en_US.UTF-8; sudo /run/current-system/sw/bin/$kind-rebuild switch --flake $src#$host --show-trace$after'"
fi
