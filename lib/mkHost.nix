# Thin wrapper around nixpkgs.lib.nixosSystem so host definitions stay
# declarative and adding a new host is a one-liner in flake.nix.
{nixpkgs}: {
  system,
  modules,
  specialArgs ? {},
}:
nixpkgs.lib.nixosSystem {
  inherit system modules specialArgs;
}
