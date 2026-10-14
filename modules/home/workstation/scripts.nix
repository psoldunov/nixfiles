# Shell scripts exposed on $PATH on both workstations. Every script defined
# here ends up in home.packages, so callers can use bare binary names instead
# of Nix store paths. Whopper-only scripts live in hosts/whopper/home/scripts.
{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  jq = lib.getExe pkgs.jq;

  # Pins overlays/claude-code to a release manifest from Anthropic's `latest`
  # channel (or the version given as $1). The manifest carries each
  # platform's sha256, so the pin is a plain file and needs no prefetch.
  update_claude_code = pkgs.writeShellScriptBin "update_claude_code" ''
    set -euo pipefail
    FLAKE_DIR="''${FLAKE_DIR:-''${HOME}/.nixfiles}"
    BASE_URL="https://downloads.claude.ai/claude-code-releases"
    TARGET="$FLAKE_DIR/overlays/claude-code/manifest.zst.json"
    VERSION="''${1:-$(${pkgs.curl}/bin/curl -fsSL "$BASE_URL/latest")}"
    if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "update_claude_code: unexpected version '$VERSION'" >&2
      exit 1
    fi
    CURRENT="$(${jq} -r .version "$TARGET" 2>/dev/null || echo none)"
    if [ "$CURRENT" = "$VERSION" ]; then
      echo "Claude Code already pinned at $VERSION."
      exit 0
    fi
    TMP="$(mktemp)"
    trap 'rm -f "$TMP"' EXIT
    ${pkgs.curl}/bin/curl -fsSL "$BASE_URL/$VERSION/manifest.zst.json" -o "$TMP"
    # Whopper runs linux-x64 and BigMac darwin-arm64.
    if ! ${jq} -e --arg v "$VERSION" \
      '.version == $v and ([.platforms["linux-x64", "darwin-arm64"].checksum]
        | all(test("^[0-9a-f]{64}$")))' \
      "$TMP" >/dev/null; then
      echo "update_claude_code: manifest for $VERSION is malformed" >&2
      exit 1
    fi
    install -m 644 "$TMP" "$TARGET"
    echo "Claude Code pin: $CURRENT -> $VERSION"
  '';

  # Pins overlays/duckstation to the newest versioned `v0.1-NNNNN` release (or
  # the version given as $1, e.g. 0.1-11894). The rolling `latest` release is
  # re-uploaded in place, so it can't hold a fixed hash. The AppImage is
  # prefetched into the store, so the next rebuild reuses it.
  update_duckstation = pkgs.writeShellScriptBin "update_duckstation" ''
    set -euo pipefail
    FLAKE_DIR="''${FLAKE_DIR:-''${HOME}/.nixfiles}"
    REPO="stenzek/duckstation"
    TARGET="$FLAKE_DIR/overlays/duckstation/pin.json"
    VERSION="''${1:-$(${pkgs.curl}/bin/curl -fsSL "https://api.github.com/repos/$REPO/releases?per_page=30" \
      | ${jq} -r '[.[] | select((.draft or .prerelease) | not) | .tag_name
          | select(test("^v0\\.1-[0-9]+$")) | ltrimstr("v")]
          | max_by(split("-")[1] | tonumber) // empty')}"
    if ! [[ "$VERSION" =~ ^0\.1-[0-9]+$ ]]; then
      echo "update_duckstation: unexpected version '$VERSION'" >&2
      exit 1
    fi
    CURRENT="$(${jq} -r .version "$TARGET" 2>/dev/null || echo none)"
    if [ "$CURRENT" = "$VERSION" ]; then
      echo "DuckStation already pinned at $VERSION."
      exit 0
    fi
    URL="https://github.com/$REPO/releases/download/v$VERSION/DuckStation-x64.AppImage"
    HASH="$(nix store prefetch-file --json "$URL" | ${jq} -r .hash)"
    if ! [[ "$HASH" =~ ^sha256-[A-Za-z0-9+/]{43}=$ ]]; then
      echo "update_duckstation: unexpected hash '$HASH' for $URL" >&2
      exit 1
    fi
    TMP="$(mktemp)"
    trap 'rm -f "$TMP"' EXIT
    ${jq} -n --arg version "$VERSION" --arg hash "$HASH" \
      '{version: $version, hash: $hash}' > "$TMP"
    install -m 644 "$TMP" "$TARGET"
    echo "DuckStation pin: $CURRENT -> $VERSION"
  '';

  # Pins overlays/motrix to the highest `vX.Y.Z[-label.N]` release that ships
  # an x86_64 AppImage (or the version given as $1, e.g. 2.0.0-beta.46).
  # Prereleases count: the 2.x line ships only as betas, so GitHub's "latest"
  # release still points at 1.8.19. Releases sort by semver, prereleases
  # below their release. The AppImage is prefetched into the store, so the
  # next rebuild reuses it.
  update_motrix = pkgs.writeShellScriptBin "update_motrix" ''
    set -euo pipefail
    FLAKE_DIR="''${FLAKE_DIR:-''${HOME}/.nixfiles}"
    REPO="agalwood/Motrix"
    TARGET="$FLAKE_DIR/overlays/motrix/pin.json"
    VERSION="''${1:-$(${pkgs.curl}/bin/curl -fsSL "https://api.github.com/repos/$REPO/releases?per_page=50" \
      | ${jq} -r '[.[] | select(.draft | not)
          | (.tag_name | ltrimstr("v")) as $v
          | select(any(.assets[]; .name == "Motrix-\($v)-x86_64.AppImage"))
          | $v | capture("^(?<maj>[0-9]+)\\.(?<min>[0-9]+)\\.(?<pat>[0-9]+)(-(?<pl>[a-z]+)\\.(?<pn>[0-9]+))?$")
          | {v: "\(.maj).\(.min).\(.pat)\(if .pl then "-\(.pl).\(.pn)" else "" end)",
             key: [(.maj | tonumber), (.min | tonumber), (.pat | tonumber),
                   (if .pl then 0 else 1 end), (.pl // ""), ((.pn // "0") | tonumber)]}]
          | max_by(.key) | .v // empty')}"
    if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-z]+\.[0-9]+)?$ ]]; then
      echo "update_motrix: unexpected version '$VERSION'" >&2
      exit 1
    fi
    CURRENT="$(${jq} -r .version "$TARGET" 2>/dev/null || echo none)"
    if [ "$CURRENT" = "$VERSION" ]; then
      echo "Motrix already pinned at $VERSION."
      exit 0
    fi
    URL="https://github.com/$REPO/releases/download/v$VERSION/Motrix-$VERSION-x86_64.AppImage"
    HASH="$(nix store prefetch-file --json "$URL" | ${jq} -r .hash)"
    if ! [[ "$HASH" =~ ^sha256-[A-Za-z0-9+/]{43}=$ ]]; then
      echo "update_motrix: unexpected hash '$HASH' for $URL" >&2
      exit 1
    fi
    TMP="$(mktemp)"
    trap 'rm -f "$TMP"' EXIT
    ${jq} -n --arg version "$VERSION" --arg hash "$HASH" \
      '{version: $version, hash: $hash}' > "$TMP"
    install -m 644 "$TMP" "$TARGET"
    echo "Motrix pin: $CURRENT -> $VERSION"
  '';

  # Pins overlays/pi-coding-agent to the newest GitHub release (or the version
  # given as $1, e.g. 1.0.4). A release needs three hashes: the source
  # tarball, its npm dependency cache (prefetch-npm-deps over the tagged
  # package-lock.json) and the matching @earendil-works/pi-ai tarball that
  # carries the model catalog. The source and pi-ai tarballs are prefetched
  # into the store, so the next rebuild reuses them.
  update_pi_coding_agent = pkgs.writeShellScriptBin "update_pi_coding_agent" ''
    set -euo pipefail
    FLAKE_DIR="''${FLAKE_DIR:-''${HOME}/.nixfiles}"
    REPO="earendil-works/pi"
    TARGET="$FLAKE_DIR/overlays/pi-coding-agent/pin.json"
    VERSION="''${1:-$(${pkgs.curl}/bin/curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
      | ${jq} -r '.tag_name // empty | ltrimstr("v")')}"
    if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "update_pi_coding_agent: unexpected version '$VERSION'" >&2
      exit 1
    fi
    CURRENT="$(${jq} -r .version "$TARGET" 2>/dev/null || echo none)"
    if [ "$CURRENT" = "$VERSION" ]; then
      echo "Pi coding agent already pinned at $VERSION."
      exit 0
    fi
    SRC="$(nix store prefetch-file --json --unpack \
      "https://github.com/$REPO/archive/refs/tags/v$VERSION.tar.gz")"
    HASH="$(${jq} -r .hash <<<"$SRC")"
    SRC_PATH="$(${jq} -r .storePath <<<"$SRC")"
    # prefetch-npm-deps prints nothing while it downloads ~360 tarballs and
    # sets no network timeout, so a stalled download would block forever.
    # Runs take 30 s to several minutes; 15 min matches its own retry window.
    echo "Prefetching pi $VERSION npm dependencies (30 s to a few minutes, no progress output)..." >&2
    if ! NPM_DEPS_HASH="$(${pkgs.coreutils}/bin/timeout 900 \
      ${pkgs.prefetch-npm-deps}/bin/prefetch-npm-deps \
      "$SRC_PATH/package-lock.json" | tail -n1)"; then
      echo "update_pi_coding_agent: npm dependency prefetch failed or stalled (15 min limit); rerun to retry" >&2
      exit 1
    fi
    MODEL_DATA_HASH="$(nix store prefetch-file --json \
      "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-$VERSION.tgz" \
      | ${jq} -r .hash)"
    for h in "$HASH" "$NPM_DEPS_HASH" "$MODEL_DATA_HASH"; do
      if ! [[ "$h" =~ ^sha256-[A-Za-z0-9+/]{43}=$ ]]; then
        echo "update_pi_coding_agent: unexpected hash '$h' for $VERSION" >&2
        exit 1
      fi
    done
    TMP="$(mktemp)"
    trap 'rm -f "$TMP"' EXIT
    ${jq} -n --arg version "$VERSION" --arg hash "$HASH" \
      --arg npmDepsHash "$NPM_DEPS_HASH" --arg modelDataHash "$MODEL_DATA_HASH" \
      '{version: $version, hash: $hash, npmDepsHash: $npmDepsHash, modelDataHash: $modelDataHash}' \
      > "$TMP"
    install -m 644 "$TMP" "$TARGET"
    echo "Pi coding agent pin: $CURRENT -> $VERSION"
  '';

  # BigMac's bleeding-edge layer: Homebrew (the agent CLIs and every cask)
  # and mise's runtimes. update_system runs it after switching BigMac.
  #
  # Casks that ship a .pkg or a privileged helper make brew call sudo part-way
  # through. sudo -v asks once, or reuses the ticket of the switch that ran
  # just before it in the same session, and the loop keeps that ticket fresh
  # until the script exits.
  update_bleeding_edge = pkgs.writeShellScriptBin "update_bleeding_edge" ''
    set -euo pipefail
    sudo -v
    while true; do sudo -n true; sleep 50; done 2>/dev/null &
    # shellcheck disable=SC2064 # the loop's pid, expanded now
    trap "kill $! 2>/dev/null" EXIT
    /opt/homebrew/bin/brew update
    # Homebrew 7 asks before upgrading; this runs unattended.
    /opt/homebrew/bin/brew upgrade --yes
    ${lib.getExe config.programs.mise.package} upgrade
  '';

  # Shared by rebuild_system, update_system and clean_system. Each host is
  # reached as psoldunov@<lower-cased name> through the ssh config
  # (./ssh.nix), and each runs either nixos-rebuild or darwin-rebuild.
  deployLib = ''
    LOCAL_HOST=${lib.escapeShellArg osConfig.networking.hostName}
    LOCAL_KIND=${
      if isDarwin
      then "darwin"
      else "nixos"
    }
    ALL_HOSTS=(Whopper BigTasty BigMac)
    declare -A KIND=([Whopper]=nixos [BigTasty]=nixos [BigMac]=darwin)

    target_of() { echo "psoldunov@''${1,,}"; }

    # keep_sudo: ask for the password once and keep sudo's ticket fresh
    # until the script exits, so later sudo calls (Homebrew's .pkg installs
    # during activation, update_bleeding_edge) reuse it instead of asking.
    keep_sudo() {
      [ -n "''${SUDO_KEEPALIVE:-}" ] && return 0
      sudo -v
      while true; do sudo -n true; sleep 50; done 2>/dev/null &
      SUDO_KEEPALIVE=$!
      trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null' EXIT
    }

    # The same for the remote side, as POSIX sh run before the switch.
    REMOTE_KEEP_SUDO='sudo -v || exit 1; while true; do sudo -n true; sleep 50; done 2>/dev/null & k=$!; trap "kill $k 2>/dev/null" EXIT'

    # hosts_for <host|all>: the hosts an argument stands for.
    hosts_for() {
      if [ "$1" = "all" ]; then
        echo "''${ALL_HOSTS[@]}"
      elif [ -n "''${KIND[$1]:-}" ]; then
        echo "$1"
      else
        echo "$PROG: unknown host '$1' (known: ''${ALL_HOSTS[*]} all)" >&2
        exit 1
      fi
    }

    # sync_repo: Whopper and BigMac both commit here, so start from the
    # other's latest push. --autostash carries uncommitted edits across.
    sync_repo() {
      if ! git pull --rebase --autostash --quiet; then
        if [ -d "$(git rev-parse --git-path rebase-merge)" ] \
          || [ -d "$(git rev-parse --git-path rebase-apply)" ]; then
          echo "$PROG: git pull stopped on a conflict; resolve it (or git rebase --abort) and rerun." >&2
          exit 1
        fi
        echo "$PROG: git pull failed; building the local tree as it is." >&2
      fi
      git add -A
    }

    # switch_host <host> [extra switch args...]: activate <host> from the
    # flake in the current directory.
    switch_host() {
      local h="$1"
      shift
      local kind="''${KIND[$h]}"
      local th
      th="$(target_of "$h")"
      if [ "$h" = "$LOCAL_HOST" ]; then
        keep_sudo
        if [ "$kind" = darwin ]; then
          sudo /run/current-system/sw/bin/darwin-rebuild switch --flake ".#$h" --show-trace "$@"
        else
          sudo nixos-rebuild switch --flake ".#$h" --show-trace "$@"
        fi
      elif [ "$kind" = nixos ] && [ "$LOCAL_KIND" = nixos ]; then
        nixos-rebuild switch --flake ".#$h" --target-host "$th" --build-host "$th" --sudo --show-trace "$@"
      else
        # macOS on either end: copy the flake and every input, the private
        # ones included, into the target's store, then build and activate
        # there. sudo asks for the target's password once over ssh -t, and
        # $AFTER_SWITCH (update_bleeding_edge for update_system) runs in the
        # same session on that ticket. A job run_hosts starts in the
        # background has no terminal to pass on, so it goes without -t.
        local src tty=-T
        src="$(nix flake archive --json \
          --to "ssh-ng://$th?remote-program=/run/current-system/sw/bin/nix-daemon" \
          | ${jq} -r .path)"
        if [ -t 0 ]; then tty=-t; fi
        # An ssh session has no LANG, and nixpkgs bash can crash on macOS 27
        # without one (NixOS/nixpkgs#570561); macOS sudo keeps LANG.
        local after="''${AFTER_SWITCH:+ && $AFTER_SWITCH}"
        ssh "$tty" "$th" "/bin/sh -c '$REMOTE_KEEP_SUDO; export LANG=en_US.UTF-8; sudo /run/current-system/sw/bin/$kind-rebuild switch --flake $src#$h --show-trace $*$after'"
      fi
    }

    # label <host>: prefix each line of stdin with [<host>].
    label() {
      local line
      while IFS= read -r line || [ -n "$line" ]; do
        printf '%-11s%s\n' "[$1]" "$line"
      done
    }

    # run_hosts <verb> <job> <host>...: run `<job> <host>` for each host.
    # A single host runs in the foreground on the terminal. Several run at
    # once, since each builds on its own machine: lines are tagged with the
    # host and copied to <logs>/<host>.log, and the call fails once all of
    # them have finished if any one failed.
    #
    # Remote sudo authenticates with the forwarded agent, so the only
    # password is the local host's, asked here before any job starts.
    # Background jobs read /dev/null, so a remote sudo that falls back to a
    # password fails instead of waiting. They also ignore SIGINT, so Ctrl-C
    # sends SIGTERM to the whole process group to stop every job.
    run_hosts() {
      local verb="$1" job="$2"
      shift 2
      if [ "$#" -eq 1 ]; then
        echo "===== $verb $1 ====="
        "$job" "$1"
        return
      fi
      local h logs i
      local -a hosts=("$@") pids=() failed=()
      for h in "$@"; do
        if [ "$h" = "$LOCAL_HOST" ]; then keep_sudo; fi
      done
      logs="$(mktemp -d "''${TMPDIR:-/tmp}/$PROG.XXXXXX")"
      echo "===== $verb $* at once (logs in $logs) ====="
      trap 'trap - INT TERM; kill 0' INT TERM
      for h in "$@"; do
        (
          set -o pipefail
          trap '[ $? -eq 0 ] || echo "===== $h FAILED, see $logs/$h.log =====" >&2' EXIT
          "$job" "$h" 2>&1 | tee "$logs/$h.log" | label "$h"
          echo "===== $h done ====="
        ) &
        pids+=("$!")
      done
      for i in "''${!pids[@]}"; do
        if ! wait "''${pids[$i]}"; then
          failed+=("''${hosts[$i]}")
        fi
      done
      trap - INT TERM
      if [ "''${#failed[@]}" -gt 0 ]; then
        echo "$PROG: failed on ''${failed[*]}; logs in $logs" >&2
        return 1
      fi
      rm -rf "$logs"
    }

    commit_and_push() {
      if ! git diff --cached --quiet || ! git diff --quiet; then
        git commit -am "$1"
      else
        echo "$PROG succeeded; nothing to commit."
      fi
      if ! git push; then
        echo "$PROG: git push failed; commits are local only." >&2
        exit 1
      fi
    }
  '';

  rebuild_system = pkgs.writeShellScriptBin "rebuild_system" ''
    set -e
    PROG=rebuild_system
    ${deployLib}
    HOSTS="$(hosts_for "''${1:-$LOCAL_HOST}")"
    cd "''${FLAKE_DIR:-''${HOME}/.nixfiles}"
    sync_repo
    # shellcheck disable=SC2086 # $HOSTS is a list of host names
    run_hosts Rebuilding switch_host $HOSTS
    commit_and_push "rebuild commit $(date '+%d/%m/%Y %H:%M:%S')"
  '';

  update_system = pkgs.writeShellScriptBin "update_system" ''
    set -e
    PROG=update_system
    ${deployLib}
    HOSTS="$(hosts_for "''${1:-$LOCAL_HOST}")"
    FLAKE_DIR="''${FLAKE_DIR:-''${HOME}/.nixfiles}"
    cd "$FLAKE_DIR"
    sync_repo
    sudo nix flake update
    FLAKE_DIR="$FLAKE_DIR" ${update_claude_code}/bin/update_claude_code
    FLAKE_DIR="$FLAKE_DIR" ${update_duckstation}/bin/update_duckstation
    FLAKE_DIR="$FLAKE_DIR" ${update_motrix}/bin/update_motrix
    FLAKE_DIR="$FLAKE_DIR" ${update_pi_coding_agent}/bin/update_pi_coding_agent
    update_host() {
      if [ "''${KIND[$1]}" = darwin ]; then
        if [ "$1" = "$LOCAL_HOST" ]; then
          switch_host "$1"
          update_bleeding_edge
        else
          AFTER_SWITCH=/etc/profiles/per-user/psoldunov/bin/update_bleeding_edge switch_host "$1"
        fi
      else
        switch_host "$1" --upgrade-all
      fi
    }
    # shellcheck disable=SC2086 # $HOSTS is a list of host names
    run_hosts Updating update_host $HOSTS
    commit_and_push "update commit $(date '+%d/%m/%Y %H:%M:%S')"
  '';

  clean_system = pkgs.writeShellScriptBin "clean_system" ''
    set -e
    PROG=clean_system
    ${deployLib}
    HOSTS="$(hosts_for "''${1:-$LOCAL_HOST}")"
    CLEAN='set -e
      sudo "$(command -v nix-collect-garbage)" -d
      nix-collect-garbage -d
      if command -v docker >/dev/null 2>&1; then docker image prune -a -f; fi
      if [ -x /opt/homebrew/bin/brew ]; then /opt/homebrew/bin/brew cleanup; fi'
    for h in $HOSTS; do
      echo "===== Cleaning $h ====="
      if [ "$h" = "$LOCAL_HOST" ]; then
        bash -c "$CLEAN"
      else
        ssh -t "$(target_of "$h")" "bash -c '$CLEAN'"
      fi
    done
  '';

  scripts =
    {
      inherit
        update_claude_code
        update_duckstation
        update_motrix
        update_pi_coding_agent
        rebuild_system
        update_system
        clean_system
        ;

      shadd = pkgs.writeShellScriptBin "shadd" ''
        ${pkgs.bun}/bin/bunx shadcn@latest add $1
      '';

      # VS Code is a cask on macOS, which puts `code` on PATH.
      sops-code = pkgs.writeShellScriptBin "sops-code" ''
        EDITOR="${
          if isDarwin
          then "code"
          else "${pkgs.vscode}/bin/code"
        } --wait" ${pkgs.sops}/bin/sops $1
      '';

      # Hardware H.264: VA-API on Whopper's Radeon, VideoToolbox on macOS.
      convert_all_to_mkv = pkgs.writeShellScriptBin "convert_all_to_mkv" ''
        DIRECTORY=$(pwd)

        for file in "$DIRECTORY"/*.mp4; do
          filename=$(basename -- "$file" .mp4)
          ${
          if isDarwin
          then ''ffmpeg -i "$file" -c:v h264_videotoolbox -q:v 65 -c:a copy "$DIRECTORY/$filename.mkv"''
          else ''ffmpeg -vaapi_device /dev/dri/renderD128 -i "$file" -vf 'format=nv12,hwupload' -c:v h264_vaapi -qp 18 -c:a copy "$DIRECTORY/$filename.mkv"''
        }
          if [ $? -eq 0 ]; then
            echo "Converted $file to $DIRECTORY/$filename.mkv successfully."
            rm "$file"
          else
            echo "Failed to convert $file. Skipping deletion."
          fi
        done
      '';

      make_timed_commit = pkgs.writeShellScriptBin "make_timed_commit" ''
        git add .
        git commit -am "commit $(date '+%d/%m/%Y %H:%M:%S')"
      '';

      convert_all_to_webp = pkgs.writeShellScriptBin "convert_all_to_webp" ''
        for img in *.{jpg,jpeg,png,gif}; do
            if [ -e "$img" ]; then
                ${pkgs.imagemagick}/bin/magick "$img" "$(echo "$img" | sed 's/\.[^.]*$//').webp" && rm "$img"
            fi
        done
      '';

      convert_all_to_woff2 = pkgs.writeShellScriptBin "convert_all_to_woff2" ''
        for font in *.{otf,ttf,woff,eot}; do
            if [ -e "$font" ]; then
                ${pkgs.woff2}/bin/woff2_compress "$font" && rm "$font"
            fi
        done
      '';
    }
    // lib.optionalAttrs isDarwin {
      inherit update_bleeding_edge;
    };
in {
  home.packages = builtins.attrValues scripts;
}
