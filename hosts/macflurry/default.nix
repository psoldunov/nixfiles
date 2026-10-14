# Entry point for MacFlurry (MacBook Pro, M1 Pro, on Wi-Fi). Aggregates the
# host's nix-darwin modules; its home-manager config is ./home, wired in
# flake.nix.
{...}: {
  imports = [
    ./modules
  ];
}
