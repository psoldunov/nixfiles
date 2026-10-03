# Figma — Linux rebuild of Figma's desktop client, from its own flake. The
# flake builds against nixpkgs' Electron 43 and installs a `figma` binary, a
# desktop entry, and icons. Bump it with `nix flake update figma`.
#
# The package is unfree, but the flake's `packages` output allows it on its
# own, so no allowUnfree entry is needed here. The figma:// handler lives in
# hosts/whopper/mime-defaults.nix; "Log in with browser" needs it to come back
# to the app.
{
  inputs,
  pkgs,
  ...
}: {
  home.packages = [
    inputs.figma.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
