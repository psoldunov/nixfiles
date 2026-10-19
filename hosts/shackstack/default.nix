# Entry point for ShackStack, the living-room HTPC. It boots straight into
# Steam's Gaming Mode (Jovian-NixOS) with Plasma as the desktop mode. The
# first install wipes the NVMe with nixos-anywhere, see ./INSTALL.md.
{...}: {
  imports = [
    ./disko.nix
    ./hardware.nix
    ./modules
  ];
}
