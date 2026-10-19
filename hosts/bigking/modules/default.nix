# BigKing-local NixOS modules: storage, shares, Syncthing and the ASUSTOR
# hardware.
# The shared baseline (boot loader, locale, nix settings, users, openssh,
# sops, docker/libvirt) is pulled in via ../../../modules/nixos.
{...}: {
  imports = [
    ../../../modules/nixos
    ../../../modules/nixos/server-monitoring
    ./monitoring.nix

    ./asustor
    ./boot.nix
    ./filesystems.nix
    ./hardware.nix
    ./networking.nix
    ./services-shares.nix
    ./syncthing.nix
    ./users.nix
  ];
}
