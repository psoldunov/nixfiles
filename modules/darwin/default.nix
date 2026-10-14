# Shared nix-darwin modules, imported by every Mac (BigMac, MacFlurry), the
# macOS counterpart of ../nixos. Each host sets its own name
# (`networking.hostName`), state version and host-only Homebrew apps in
# hosts/<host>/modules.
{...}: {
  imports = [
    ./homebrew.nix
    ./nix.nix
    ./overlays.nix
    ./sops.nix
    ./system.nix
  ];
}
