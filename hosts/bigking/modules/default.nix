# BigKing-local NixOS modules: storage, shares and the ASUSTOR hardware.
# The shared baseline (boot loader, locale, nix settings, users, openssh,
# sops, docker/libvirt) is pulled in via ../../../modules/nixos.
{...}: {
  imports = [
    ../../../modules/nixos

    ./asustor
    ./boot.nix
    ./filesystems.nix
    ./hardware.nix
    ./networking.nix
    ./services-shares.nix
    ./users.nix
  ];
}
