# Lunear — Linux rebuild of Linear's desktop client, from its own flake. The
# flake builds against nixpkgs' Electron 43 and installs a `linear` binary, a
# desktop entry, and icons. Bump it with `nix flake update lunear`.
#
# The package is unfree, but the flake's `packages` output allows it on its
# own, so no allowUnfree entry is needed here. The linear:// handler lives in
# hosts/whopper/mime-defaults.nix; sign-in through the browser needs it.
{
  inputs,
  pkgs,
  ...
}: {
  home.packages = [
    inputs.lunear.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
