# Whopper-local nix knobs: nix-path, the gaming binary cache, and build
# throttling so a heavy rebuild doesn't bog down the desktop.
# The host-agnostic settings (warn-dirty, experimental-features,
# auto-optimise-store, trusted-users) live in modules/nixos/nix.nix.
{inputs, ...}: {
  nix = {
    settings.nix-path = ["nixpkgs=${inputs.nixpkgs}"];

    # Builds only get CPU time and disk I/O that nothing else wants, so
    # interactive work always preempts them.
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";

    settings = {
      # 4 derivations x 4 threads = 16 of 24 threads at most. The defaults
      # (24 x all cores) can oversubscribe the CPU and blow through RAM on
      # big C++ builds.
      max-jobs = 4;
      cores = 4;

      substituters = [
        "https://cache.nixos.org/"
        "https://nix-gaming.cachix.org"
      ];
      trusted-public-keys = [
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      ];
    };
  };
}
