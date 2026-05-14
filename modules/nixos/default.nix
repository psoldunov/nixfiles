# Shared NixOS modules. Imported by every host. Each module captures the
# host-agnostic baseline; host-local modules add or override per-host
# specifics (firewall ports, GPU vendor packages, secrets, etc.).
{...}: {
  imports = [
    ./boot.nix
    ./locale.nix
    ./nix.nix
    ./openssh.nix
    ./users.nix
    ./sops.nix
    ./virtualisation.nix
    ./hardware.nix
    ./programs.nix
  ];
}
