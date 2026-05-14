# Entry point for the Whopper host. Aggregates hardware, host-specific
# tweaks, and the shared modules/nixos tree.
{...}: {
  imports = [
    ./hardware.nix
    ./modules
  ];
}
