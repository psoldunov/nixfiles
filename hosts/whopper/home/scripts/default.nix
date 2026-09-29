# Shell scripts exposed on $PATH. This is a proper HM module (not a raw
# attrset) — every script defined here ends up in home.packages, so
# callers can use bare binary names instead of Nix store paths.
{
  pkgs,
  ...
}: let
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

  alwaysOn = {
    inherit update_claude_code;

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
