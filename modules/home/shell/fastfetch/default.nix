# Fastfetch on every host. The config itself lives in ./settings.nix and the
# pseudo-3D logos in ./logos (regenerate them with ./logos/make-logo.py).
# The icons need a Nerd Font in the terminal that shows them: Ghostty on the
# workstations, which SSH sessions to the servers go through as well.
{
  lib,
  pkgs,
  hostConfig,
  ...
}: {
  programs.fastfetch = {
    enable = true;
    settings = import ./settings.nix {
      inherit lib;
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
      isDesktop = hostConfig.role == "desktop";
    };
  };
}
