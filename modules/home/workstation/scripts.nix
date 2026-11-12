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

  # Pins overlays/codex to the newest stable `rust-vX.Y.Z` release (or the
  # version given as $1, e.g. 0.167.0). The x86_64 musl package is
  # prefetched into the store, so the next rebuild reuses it.
  update_codex = pkgs.writeShellScriptBin "update_codex" ''
    set -euo pipefail
    FLAKE_DIR="''${FLAKE_DIR:-''${HOME}/.nixfiles}"
    REPO="openai/codex"
    TARGET="$FLAKE_DIR/overlays/codex/pin.json"
    VERSION="''${1:-$(${pkgs.curl}/bin/curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
      | ${jq} -r '.tag_name // empty | ltrimstr("rust-v")')}"
    if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "update_codex: unexpected version '$VERSION'" >&2
      exit 1
    fi
    CURRENT="$(${jq} -r .version "$TARGET" 2>/dev/null || echo none)"
    if [ "$CURRENT" = "$VERSION" ]; then
      echo "Codex already pinned at $VERSION."
      exit 0
    fi
    URL="https://github.com/$REPO/releases/download/rust-v$VERSION/codex-package-x86_64-unknown-linux-musl.tar.zst"
    HASH="$(nix store prefetch-file --json "$URL" | ${jq} -r .hash)"
    if ! [[ "$HASH" =~ ^sha256-[A-Za-z0-9+/]{43}=$ ]]; then
      echo "update_codex: unexpected hash '$HASH' for $URL" >&2
      exit 1
    fi
    TMP="$(mktemp)"
    trap 'rm -f "$TMP"' EXIT
    ${jq} -n --arg version "$VERSION" --arg hash "$HASH" \
      '{version: $version, hash: $hash}' > "$TMP"
    install -m 644 "$TMP" "$TARGET"
    echo "Codex pin: $CURRENT -> $VERSION"
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

  # The Macs' bleeding-edge layer: Homebrew (the agent CLIs and every cask)
  # and mise's runtimes. `fleet update` runs it after switching a Mac.
  #
  # Casks that ship a .pkg or a privileged helper make brew call sudo part-way
  # through. sudo -v asks once, or reuses the ticket of the switch that ran
  # just before it in the same session, and the loop keeps that ticket fresh
  # until the script exits.
  #
  # Without a tty (fleet runs several hosts with ssh -T), sudo keys the ticket to
  # the parent process, so the loop's `sudo -n` fails and set -e ends the
  # loop at once. The trap's kill then finds nothing, and `|| true` stops
  # that failure from becoming the script's exit status.
  update_bleeding_edge = pkgs.writeShellScriptBin "update_bleeding_edge" ''
    set -euo pipefail
    sudo -v
    while true; do sudo -n true; sleep 50; done 2>/dev/null &
    # shellcheck disable=SC2064 # the loop's pid, expanded now
    trap "kill $! 2>/dev/null || true" EXIT
    /opt/homebrew/bin/brew update
    # Homebrew 7 asks before upgrading; this runs unattended.
    /opt/homebrew/bin/brew upgrade --yes
    ${lib.getExe config.programs.mise.package} upgrade
  '';

  # The hosts fleet (packages/fleet) works on, each reached as
  # <user>@<lower-cased name> through the ssh config (./ssh.nix).
  # - roaming: often asleep or away, so `all` skips it when it doesn't answer.
  # - last: switched alone, after the others. The rest of the fleet resolves
  #   names through PiHome, and a switch that restarts AdGuard or Unbound
  #   would break their downloads mid-build.
  # - buildsItself: the builder (Whopper) builds every other NixOS host, so a
  #   derivation several hosts share (Concierge's crates, kernel modules,
  #   Plasma bits) compiles once, on the fastest machine. PiHome is aarch64.
  # - sleep: fleet may suspend it. wakeMac: its Wake-on-LAN address
  #   (ShackStack's from hosts/shackstack/INSTALL.md, Whopper's enp10s0).
  fleetHosts = [
    {
      name = "Whopper";
      kind = "nixos";
      sleep = true;
      wakeMac = "98:b7:85:1f:2c:9a";
    }
    {
      name = "BigTasty";
      kind = "nixos";
    }
    {
      name = "BigKing";
      kind = "nixos";
    }
    {
      name = "ShackStack";
      kind = "nixos";
      roaming = true;
      sleep = true;
      wakeMac = "cc:28:aa:86:dd:6a";
    }
    {
      name = "BigMac";
      kind = "darwin";
      roaming = true;
      sleep = true;
    }
    {
      name = "MacFlurry";
      kind = "darwin";
      roaming = true;
      sleep = true;
    }
    {
      name = "PiHome";
      kind = "nixos";
      last = true;
      buildsItself = true;
    }
  ];

  # Rebuilds, updates and cleans the hosts, reboots, suspends and wakes them,
  # and keeps a report of every run that `fleet fix` hands to an agent.
  fleet = pkgs.callPackage ../../../packages/fleet {
    config = {
      localHost = osConfig.networking.hostName;
      sshUser = config.home.username;
      builder = "Whopper";
      hosts = fleetHosts;
      # `fleet update` runs these, in this order, after `nix flake update`.
      pins = map lib.getExe [
        update_claude_code
        update_duckstation
        update_motrix
        update_codex
        update_pi_coding_agent
      ];
      bleedingEdge =
        if isDarwin
        then lib.getExe update_bleeding_edge
        else null;
      remoteBleedingEdge = "/etc/profiles/per-user/${config.home.username}/bin/update_bleeding_edge";
      gum = lib.getExe pkgs.gum;
      # The subnet broadcast rather than 255.255.255.255, so the packet leaves
      # on the LAN interface even when another one holds the default route.
      wolBroadcast = "10.24.24.255";
    };
  };

  # The old script names, for muscle memory, the docs and the agents that
  # call them. With no host they act on this machine, as they always did.
  fleetAlias = name: action:
    pkgs.writeShellScriptBin name ''
      if [ "$#" -eq 0 ]; then set -- ${lib.escapeShellArg osConfig.networking.hostName}; fi
      exec ${lib.getExe fleet} ${action} "$@"
    '';

  scripts =
    {
      inherit
        update_claude_code
        update_duckstation
        update_motrix
        update_codex
        update_pi_coding_agent
        fleet
        ;

      rebuild_system = fleetAlias "rebuild_system" "rebuild";
      update_system = fleetAlias "update_system" "update";
      clean_system = fleetAlias "clean_system" "clean";

      # shackstack-tv-sleep puts the TV in standby on the way down.
      shackstack-sleep = pkgs.writeShellScriptBin "shackstack-sleep" ''
        exec ${lib.getExe fleet} sleep ShackStack
      '';
      shackstack-wake = pkgs.writeShellScriptBin "shackstack-wake" ''
        exec ${lib.getExe fleet} wake ShackStack
      '';

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
        status=0
        set -C # the only redirect below is the claim on the output file
        for img in *.{jpg,jpeg,png,gif}; do
            [ -e "$img" ] || continue
            dest="''${img%.*}.webp"
            # Never overwrite: photo.jpg and photo.png share photo.webp, and a
            # symlink (even dangling) would redirect the write elsewhere.
            if [ -e "$dest" ] || [ -L "$dest" ]; then
                echo "Refusing $img: $dest already exists. Keeping $img." >&2
                status=1
                continue
            fi
            # The check above is only for a friendly message. This open is the
            # claim: noclobber makes it O_EXCL (no reuse, no symlink follow), so
            # a concurrent run or a file planted since loses. Nothing is deleted
            # unless it succeeds, so a foreign $dest is never touched.
            if ! { exec 3> "$dest"; } 2>/dev/null; then
                echo "Refusing $img: could not create $dest. Keeping $img." >&2
                status=1
                continue
            fi
            # magick writes to stdout (the fd we own), so it never reads the
            # output name: %d, %o or a "format:" prefix in it mean nothing.
            if ${pkgs.imagemagick}/bin/magick "./$img" webp:- >&3 3>&-; then
                exec 3>&-
                rm -- "$img" || status=1
            else
                exec 3>&-
                echo "Failed to convert $img. Keeping it." >&2
                rm -f -- "$dest"
                status=1
            fi
        done
        exit $status
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
