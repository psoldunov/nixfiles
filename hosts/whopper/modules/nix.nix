# Whopper-local nix knobs: nix-path, the gaming binary cache, and build
# throttling so a heavy rebuild doesn't bog down the desktop.
# The host-agnostic settings (warn-dirty, experimental-features,
# auto-optimise-store, trusted-users) live in modules/nixos/nix.nix.
{
  config,
  inputs,
  ...
}: {
  nix = {
    settings.nix-path = ["nixpkgs=${inputs.nixpkgs}"];

    # GitHub token for private flake inputs, such as psoldunov/linear and
    # psoldunov/figma. It is the fine-grained PAT "nix-private-flake":
    # read-only Contents, scoped to the private repos the flake pulls; grant it
    # each new one there.
    # `!include` skips a missing file, so evaluation still works before
    # sops-nix has decrypted the secret.
    extraOptions = ''
      !include ${config.sops.secrets.NIX_ACCESS_TOKENS.path}
    '';

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
