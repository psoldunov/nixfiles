# Shell scripts exposed on $PATH. This is a proper HM module (not a raw
# attrset) — every script defined here ends up in home.packages, so
# callers can use bare binary names instead of Nix store paths.
{pkgs, ...}: let
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
    CURRENT="$(${pkgs.jq}/bin/jq -r .version "$TARGET" 2>/dev/null || echo none)"
    if [ "$CURRENT" = "$VERSION" ]; then
      echo "Claude Code already pinned at $VERSION."
      exit 0
    fi
    TMP="$(mktemp)"
    trap 'rm -f "$TMP"' EXIT
    ${pkgs.curl}/bin/curl -fsSL "$BASE_URL/$VERSION/manifest.zst.json" -o "$TMP"
    if ! ${pkgs.jq}/bin/jq -e --arg v "$VERSION" \
      '.version == $v and (.platforms["linux-x64"].checksum | test("^[0-9a-f]{64}$"))' \
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
      | ${pkgs.jq}/bin/jq -r '[.[] | select((.draft or .prerelease) | not) | .tag_name
          | select(test("^v0\\.1-[0-9]+$")) | ltrimstr("v")]
          | max_by(split("-")[1] | tonumber) // empty')}"
    if ! [[ "$VERSION" =~ ^0\.1-[0-9]+$ ]]; then
      echo "update_duckstation: unexpected version '$VERSION'" >&2
      exit 1
    fi
    CURRENT="$(${pkgs.jq}/bin/jq -r .version "$TARGET" 2>/dev/null || echo none)"
    if [ "$CURRENT" = "$VERSION" ]; then
      echo "DuckStation already pinned at $VERSION."
      exit 0
    fi
    URL="https://github.com/$REPO/releases/download/v$VERSION/DuckStation-x64.AppImage"
    HASH="$(nix store prefetch-file --json "$URL" | ${pkgs.jq}/bin/jq -r .hash)"
    if ! [[ "$HASH" =~ ^sha256-[A-Za-z0-9+/]{43}=$ ]]; then
      echo "update_duckstation: unexpected hash '$HASH' for $URL" >&2
      exit 1
    fi
    TMP="$(mktemp)"
    trap 'rm -f "$TMP"' EXIT
    ${pkgs.jq}/bin/jq -n --arg version "$VERSION" --arg hash "$HASH" \
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
      | ${pkgs.jq}/bin/jq -r '[.[] | select(.draft | not)
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
    CURRENT="$(${pkgs.jq}/bin/jq -r .version "$TARGET" 2>/dev/null || echo none)"
    if [ "$CURRENT" = "$VERSION" ]; then
      echo "Motrix already pinned at $VERSION."
      exit 0
    fi
    URL="https://github.com/$REPO/releases/download/v$VERSION/Motrix-$VERSION-x86_64.AppImage"
    HASH="$(nix store prefetch-file --json "$URL" | ${pkgs.jq}/bin/jq -r .hash)"
    if ! [[ "$HASH" =~ ^sha256-[A-Za-z0-9+/]{43}=$ ]]; then
      echo "update_motrix: unexpected hash '$HASH' for $URL" >&2
      exit 1
    fi
    TMP="$(mktemp)"
    trap 'rm -f "$TMP"' EXIT
    ${pkgs.jq}/bin/jq -n --arg version "$VERSION" --arg hash "$HASH" \
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
      | ${pkgs.jq}/bin/jq -r '.tag_name // empty | ltrimstr("v")')}"
    if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "update_pi_coding_agent: unexpected version '$VERSION'" >&2
      exit 1
    fi
    CURRENT="$(${pkgs.jq}/bin/jq -r .version "$TARGET" 2>/dev/null || echo none)"
    if [ "$CURRENT" = "$VERSION" ]; then
      echo "Pi coding agent already pinned at $VERSION."
      exit 0
    fi
    SRC="$(nix store prefetch-file --json --unpack \
      "https://github.com/$REPO/archive/refs/tags/v$VERSION.tar.gz")"
    HASH="$(${pkgs.jq}/bin/jq -r .hash <<<"$SRC")"
    SRC_PATH="$(${pkgs.jq}/bin/jq -r .storePath <<<"$SRC")"
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
      | ${pkgs.jq}/bin/jq -r .hash)"
    for h in "$HASH" "$NPM_DEPS_HASH" "$MODEL_DATA_HASH"; do
      if ! [[ "$h" =~ ^sha256-[A-Za-z0-9+/]{43}=$ ]]; then
        echo "update_pi_coding_agent: unexpected hash '$h' for $VERSION" >&2
        exit 1
      fi
    done
    TMP="$(mktemp)"
    trap 'rm -f "$TMP"' EXIT
    ${pkgs.jq}/bin/jq -n --arg version "$VERSION" --arg hash "$HASH" \
      --arg npmDepsHash "$NPM_DEPS_HASH" --arg modelDataHash "$MODEL_DATA_HASH" \
      '{version: $version, hash: $hash, npmDepsHash: $npmDepsHash, modelDataHash: $modelDataHash}' \
      > "$TMP"
    install -m 644 "$TMP" "$TARGET"
    echo "Pi coding agent pin: $CURRENT -> $VERSION"
  '';

  alwaysOn = {
    inherit update_claude_code update_duckstation update_motrix update_pi_coding_agent;

    shadd = pkgs.writeShellScriptBin "shadd" ''
      ${pkgs.bun}/bin/bunx shadcn@latest add $1
    '';

    convert_all_to_mkv = pkgs.writeShellScriptBin "convert_all_to_mkv" ''
      DIRECTORY=$(pwd)

      for file in "$DIRECTORY"/*.mp4; do
        filename=$(basename -- "$file" .mp4)
        ffmpeg -vaapi_device /dev/dri/renderD128 -i "$file" -vf 'format=nv12,hwupload' -c:v h264_vaapi -qp 18 -c:a copy "$DIRECTORY/$filename.mkv"
        if [ $? -eq 0 ]; then
          echo "Converted $file to $DIRECTORY/$filename.mkv successfully."
          rm "$file"
        else
          echo "Failed to convert $file. Skipping deletion."
        fi
      done
    '';

    sops-code = pkgs.writeShellScriptBin "sops-code" ''
      EDITOR="${pkgs.vscode}/bin/code --wait" ${pkgs.sops}/bin/sops $1
    '';

    kill_gamescope = pkgs.writeShellScriptBin "kill_gamescope" ''
      pkill -9 wine steam wineserver winedevice.exe explorer.exe gamescope plugplay.exe services.exe svchost.exe rpcss.exe .exe
    '';

    update_system = pkgs.writeShellScriptBin "update_system" ''
      set -e
      HOST="''${1:-$(${pkgs.inetutils}/bin/hostname)}"
      FLAKE_DIR="''${HOME}/.nixfiles"
      ALL_HOSTS=(Whopper BigTasty)
      cd "$FLAKE_DIR"
      git add -A
      sudo nix flake update
      FLAKE_DIR="$FLAKE_DIR" ${update_claude_code}/bin/update_claude_code
      FLAKE_DIR="$FLAKE_DIR" ${update_duckstation}/bin/update_duckstation
      FLAKE_DIR="$FLAKE_DIR" ${update_motrix}/bin/update_motrix
      FLAKE_DIR="$FLAKE_DIR" ${update_pi_coding_agent}/bin/update_pi_coding_agent
      LOCAL_HOST="$(${pkgs.inetutils}/bin/hostname)"
      deploy_one() {
        local h="$1"
        echo "===== Updating $h ====="
        if [ "$h" = "$LOCAL_HOST" ]; then
          sudo nixos-rebuild switch --flake ".#$h" --show-trace --upgrade-all
        else
          local th="psoldunov@''${h,,}"
          nixos-rebuild switch --flake ".#$h" --target-host "$th" --build-host "$th" --sudo --show-trace --upgrade-all
        fi
      }
      if [ "$HOST" = "all" ]; then
        for h in "''${ALL_HOSTS[@]}"; do deploy_one "$h"; done
      else
        deploy_one "$HOST"
      fi
      if ! git diff --cached --quiet || ! git diff --quiet; then
        git commit -am "update commit $(date '+%d/%m/%Y %H:%M:%S')"
      else
        echo "Update succeeded; nothing to commit."
      fi
      if ! git push; then
        echo "update_system: git push failed; commits are local only." >&2
        exit 1
      fi
    '';

    rebuild_system = pkgs.writeShellScriptBin "rebuild_system" ''
      set -e
      HOST="''${1:-$(${pkgs.inetutils}/bin/hostname)}"
      FLAKE_DIR="''${HOME}/.nixfiles"
      ALL_HOSTS=(Whopper BigTasty)
      cd "$FLAKE_DIR"
      git add -A
      LOCAL_HOST="$(${pkgs.inetutils}/bin/hostname)"
      deploy_one() {
        local h="$1"
        echo "===== Rebuilding $h ====="
        if [ "$h" = "$LOCAL_HOST" ]; then
          sudo nixos-rebuild switch --flake ".#$h" --show-trace
        else
          local th="psoldunov@''${h,,}"
          nixos-rebuild switch --flake ".#$h" --target-host "$th" --build-host "$th" --sudo --show-trace
        fi
      }
      if [ "$HOST" = "all" ]; then
        for h in "''${ALL_HOSTS[@]}"; do deploy_one "$h"; done
      else
        deploy_one "$HOST"
      fi
      if ! git diff --cached --quiet || ! git diff --quiet; then
        git commit -am "rebuild commit $(date '+%d/%m/%Y %H:%M:%S')"
      else
        echo "Rebuild succeeded; nothing to commit."
      fi
      if ! git push; then
        echo "rebuild_system: git push failed; commits are local only." >&2
        exit 1
      fi
    '';

    clean_system = pkgs.writeShellScriptBin "clean_system" ''
      set -e
      HOST="''${1:-$(${pkgs.inetutils}/bin/hostname)}"
      ALL_HOSTS=(Whopper BigTasty)
      LOCAL_HOST="$(${pkgs.inetutils}/bin/hostname)"
      clean_one() {
        local h="$1"
        echo "===== Cleaning $h ====="
        if [ "$h" = "$LOCAL_HOST" ]; then
          sudo nix-collect-garbage -d
          nix-collect-garbage -d
          if command -v docker >/dev/null 2>&1; then
            docker image prune -a -f
          fi
        else
          local th="psoldunov@''${h,,}"
          ssh -t "$th" "bash -c 'set -e; sudo nix-collect-garbage -d; nix-collect-garbage -d; if command -v docker >/dev/null 2>&1; then docker image prune -a -f; fi'"
        fi
      }
      if [ "$HOST" = "all" ]; then
        for h in "''${ALL_HOSTS[@]}"; do clean_one "$h"; done
      else
        clean_one "$HOST"
      fi
    '';

    make_timed_commit = pkgs.writeShellScriptBin "make_timed_commit" ''
      git add .
      git commit -am "commit $(date '+%d/%m/%Y %H:%M:%S')"
    '';

    restart_steam = pkgs.writeShellScriptBin "restart_steam" ''
      pkill -9 steam && steam & disown
      exit 0
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
  };

  scripts = alwaysOn;
in {
  home.packages = builtins.attrValues scripts;
}
