# BigMac's nix-darwin modules. There is no shared darwin baseline yet:
# with one Mac, everything system-level lives here.
{...}: {
  imports = [
    ./homebrew.nix
    ./nix.nix
    ./overlays.nix
    ./sops.nix
    ./system.nix
  ];
}
