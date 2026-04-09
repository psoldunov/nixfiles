{...}: {
  imports = [
    ./boot.nix
    ./desktop-environment.nix
    ./fonts.nix
    ./hardware.nix
    ./locale.nix
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
