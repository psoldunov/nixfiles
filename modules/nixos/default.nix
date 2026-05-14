# Shared NixOS module aggregator. Always-imported modules live in `core`;
# desktop-only modules import behind `hostConfig.role == "desktop"`. Server
# hosts assemble their own networking/services/packages under
# `hosts/<host>/modules/`.
{
  lib,
  hostConfig,
  ...
}: let
  core = [
    ./boot.nix
    ./locale.nix
    ./nix.nix
    ./overlays.nix
    ./security.nix
    ./sops.nix
    ./users.nix
  ];

  desktop = [
    ./desktop-environment.nix
    ./fonts.nix
    ./hardware.nix
    ./mounts.nix
    ./networking.nix
    ./packages.nix
    ./services.nix
    ./virtualisation.nix
  ];
in {
  imports = core ++ lib.optionals (hostConfig.role == "desktop") desktop;
}
