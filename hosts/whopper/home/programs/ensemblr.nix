# Ensemblr's Rust/GPUI build, from the concierge flake (bump with
# `nix flake update concierge`).
#
# The module installs the daemon, CLI (`ensemblr`) and app (`ensemblr-app`),
# runs the daemon as the systemd user unit `ensemblr-daemon.service` and
# starts the app hidden with the graphical session as `ensemblr-ui.service`.
# A switch restarts neither; the new build takes over after
# `systemctl --user restart ensemblr-daemon`.
{
  inputs,
  osConfig,
  pkgs,
  ...
}: {
  imports = [
    inputs.concierge.homeManagerModules.ensemblr
  ];

  programs.ensemblr = {
    enable = true;
    ui.autostart = true;
    # The range the firewall opens (../../modules/networking.nix).
    portRange = {inherit (osConfig.programs.ensemblr.portRange) from to;};
    # shortcut: nixpkgs#537108's cargo hook points JEMALLOC_OVERRIDE at a
    # system jemalloc that doesn't exist; the package builds its own. Drop
    # once psoldunov/concierge's nix/ensemblr.nix sets dontCargoUseSystemLibs.
    package = inputs.concierge.packages.${pkgs.stdenv.hostPlatform.system}.ensemblr.overrideAttrs {
      dontCargoUseSystemLibs = true;
    };
  };
}
