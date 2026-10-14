# Entry point for BigMac (macOS on Apple silicon). Aggregates the host's
# nix-darwin modules; its home-manager config is ./home, wired in flake.nix.
{...}: {
  imports = [
    ./modules
  ];
}
