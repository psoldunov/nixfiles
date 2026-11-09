# Notion — Linux rebuild of Notion's desktop client, from its own flake. The
# flake builds against nixpkgs' Electron 43 and installs a `notion` binary, a
# desktop entry, and icons. Bump it with `nix flake update notion`.
#
# The package is unfree, but the flake's `packages` output allows it on its
# own, so no allowUnfree entry is needed here. The notion:// handler lives in
# hosts/whopper/mime-defaults.nix; sign-in through the browser needs it.
#
# Started at login: --open-at-login loads Notion's window without showing it.
# The tray icon is Notion's own setting: it shows while both the menu bar icon
# and Command Search are on. Notion's "Open at login" writes this same file
# name; leave it on, since switching it off deletes this entry.
{
  inputs,
  lib,
  pkgs,
  ...
}: let
  upstream = inputs.notion.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # shortcut: the flake follows our nixpkgs, which moved bun from 1.4.2 to
  # 1.4.4, and the node_modules bun 1.4.4 installs no longer match notion's
  # hash, so the fixed-output build fails. Pin the new hash while notion still
  # carries the old one; once psoldunov/notion bumps it, this warns instead.
  staleHash = "sha256-fzRhkscqF/U9zsk+uGrgB+35nVwpXnDCduDVkKepc78=";
  bunHash = "sha256-mb0msCB22VBxb7eVwfiSps4sYanGUYSUVK9Vr/CuvMI=";
  notion =
    if upstream.nodeModules.outputHash == staleHash
    then
      upstream.override (old: {
        callPackage = fn: args:
          (old.callPackage fn args).overrideAttrs {outputHash = bunHash;};
      })
    else lib.warn "hosts/whopper/home/programs/notion.nix: notion's node_modules hash changed upstream; drop the override" upstream;
in {
  home.packages = [notion];

  xdg.configFile."autostart/notion.desktop" = {
    source = "${pkgs.makeDesktopItem {
      name = "notion";
      desktopName = "Notion";
      icon = "notion-desktop";
      exec = "${lib.getExe notion} --open-at-login";
      terminal = false;
    }}/share/applications/notion.desktop";
    force = true;
  };
}
