# Notion — Linux rebuild of Notion's desktop client, from its own flake. The
# flake builds against nixpkgs' Electron 43 and installs a `notion` binary, a
# desktop entry, and icons. Bump it with `nix flake update notion`.
#
# The package is unfree, but the flake's `packages` output allows it on its
# own, so no allowUnfree entry is needed here. The notion:// handler lives in
# hosts/whopper/mime-defaults.nix; sign-in through the browser needs it.
{
  inputs,
  pkgs,
  ...
}: {
  home.packages = [
    inputs.notion.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
