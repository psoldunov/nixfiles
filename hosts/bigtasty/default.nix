# Entry point for the BigTasty host. Aggregates hardware + decomposed
# server modules.
{...}: {
  imports = [
    ./hardware.nix
    ./modules
  ];
}
