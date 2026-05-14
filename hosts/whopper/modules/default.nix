# Whopper-local NixOS modules. The shared baseline (boot loader, locale,
# nix settings, users, sops preamble, virtualisation, fwupd, …) lives
# under ../../../modules/nixos and is imported below.
{...}: {
  imports = [
    ../../../modules/nixos

    ./boot.nix
    ./desktop-environment.nix
    ./fonts.nix
    ./hardware.nix
    ./mounts.nix
    ./networking.nix
    ./nix.nix
    ./overlays.nix
    ./packages.nix
    ./security.nix
    ./services.nix
    ./sops.nix
    ./users.nix
    ./virtualisation.nix
  ];
}
