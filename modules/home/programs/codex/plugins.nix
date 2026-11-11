# Codex plugins, installed as real directories under ~/.codex/plugins/cache/.
#
# Home Manager's programs.codex.plugins links each plugin's cache entry into
# the Nix store, and Codex (0.167) lists a linked entry as "not installed", so
# none of them loaded. This module writes the same marketplace and config keys,
# then activation copies each plugin into place. The marketplace keeps Home
# Manager's name, so the `<plugin>@home-manager` keys already in the mutable
# config.toml stay valid.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  marketplace = "home-manager";
  cacheDir = ".codex/plugins/cache/${marketplace}";

  sources = {
    # Since 2.1 the repo root is a marketplace; the built plugin (server.mjs,
    # hook.mjs, .codex-plugin/) lives in plugins/claude-code.
    context-mode = "${inputs.context-mode}/plugins/claude-code";
    ponytail = "${inputs.ponytail}";
  };

  plugins =
    lib.mapAttrs (
      name: src: let
        manifest = lib.importJSON "${src}/.codex-plugin/plugin.json";
      in
        lib.throwIf (manifest.name != name) "codex: plugin ${name} calls itself ${manifest.name} in its manifest" {
          inherit src;
          inherit (manifest) version;
        }
    )
    sources;

  marketplaceJson = {
    name = marketplace;
    interface.displayName = "Home Manager";
    plugins =
      lib.mapAttrsToList (name: plugin: {
        inherit name;
        category = "Productivity";
        # Relative to the marketplace root, which is $HOME for ~/.agents/plugins.
        source = {
          source = "local";
          path = "./${cacheDir}/${name}/${plugin.version}";
        };
        policy = {
          installation = "AVAILABLE";
          authentication = "ON_INSTALL";
        };
      })
      plugins;
  };

  cp = "${pkgs.coreutils}/bin/cp";
in {
  config = lib.mkIf config.programs.codex.enable {
    programs.codex.settings = {
      features.plugins = true;
      plugins = lib.mapAttrs' (name: _: lib.nameValuePair "${name}@${marketplace}" {enabled = true;}) plugins;
    };

    home.file.".agents/plugins/marketplace.json".text = builtins.toJSON marketplaceJson;

    # After linkGeneration, which has already removed the links an older
    # generation put at these paths. A copy is redone only when its store path
    # changes, so state a plugin writes into its own folder survives rebuilds.
    home.activation.codexPlugins = lib.hm.dag.entryAfter ["linkGeneration"] (
      ''
        installCodexPlugin() {
          local src=$1 dir="$HOME/${cacheDir}/$2" version=$3
          if [ "$(cat "$dir/$version/.nix-source" 2>/dev/null)" = "$src" ]; then
            return 0
          fi
          # The whole plugin folder goes: older versions and stale links with it.
          run rm -rf "$dir"
          run mkdir -p "$dir"
          run ${cp} -R "$src" "$dir/$version"
          run chmod -R u+w "$dir/$version"
          if [ -z "''${DRY_RUN:-}" ]; then
            printf '%s' "$src" > "$dir/$version/.nix-source"
          fi
        }
      ''
      + lib.concatStrings (lib.mapAttrsToList (name: plugin: ''
          installCodexPlugin ${lib.escapeShellArgs [plugin.src name plugin.version]}
        '')
        plugins)
    );
  };
}
