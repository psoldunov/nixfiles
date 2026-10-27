# Ensemblr's Rust/GPUI build, from the concierge flake (bump with
# `nix flake update concierge`). Installed beside the Electron
# `ensemblr-master` in ../packages.nix for QA; the two keep separate data.
#
# The module installs the daemon, CLI and app, runs the daemon as the systemd
# user unit `ensemblr-daemon.service` and starts the app hidden with the
# graphical session as `ensemblr-ui.service`. A switch restarts neither; the
# new build takes over after `systemctl --user restart ensemblr-daemon`.
#
# Both packages ship `bin/ensemblr`. The Rust package sets priority 6, so the
# Electron launcher keeps that name; run the Rust CLI by its store path or
# `ensemblr-app` for the app.
{inputs, ...}: {
  imports = [
    inputs.concierge.homeManagerModules.ensemblr
  ];

  programs.ensemblr = {
    enable = true;
    ui.autostart = true;
  };
}
