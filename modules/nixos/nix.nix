# nix / nixpkgs / nix-ld baseline shared across hosts.
# Host-local nix.nix files add cachix substituters, nix-path, and the
# `allowUnfreePredicate` / per-host `permittedInsecurePackages` entries
# (the list type means hosts can append without conflict).
{pkgs, ...}: {
  nix.settings = {
    warn-dirty = false;
    experimental-features = ["nix-command" "flakes"];
    auto-optimise-store = true;
    trusted-users = ["psoldunov"];
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowInsecure = true;
    allowBroken = true;
  };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    # pi-lens downloads Marksman's .NET binary, which aborts without ICU.
    # That release finds ICU 77 but does not discover the default ICU 78.
    icu77
  ];

  system.stateVersion = "23.11";
}
