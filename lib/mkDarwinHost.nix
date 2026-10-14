# nix-darwin counterpart of ./mkHost.nix. The platform comes from the host's
# own `nixpkgs.hostPlatform`, so only modules and specialArgs pass through.
{nix-darwin}: {
  modules,
  specialArgs ? {},
}:
nix-darwin.lib.darwinSystem {
  inherit modules specialArgs;
}
