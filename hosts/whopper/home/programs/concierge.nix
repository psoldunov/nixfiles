# Concierge — Claude for work outside code repositories, from its own flake.
# Bump it with `nix flake update concierge`.
#
# Installs the git channel: the flake has no release channel and builds the
# locked master commit from source, so the first build compiles the whole
# Rust workspace. The module installs the package (daemon, `concierge` CLI and
# the `concierge-linux` app), runs the daemon as the systemd user unit
# `concierge-daemon.service` from login, and starts the app hidden with the
# graphical session as `concierge-ui.service`.
#
# A switch restarts neither unit, so running Tasks and open windows survive
# it; the new build takes over at the next login, or after
# `systemctl --user restart concierge-daemon`.
#
# The daemon finds `claude` through the login shell's PATH, which
# home-manager's programs.claude-code already puts there.
{inputs, ...}: {
  imports = [
    inputs.concierge.homeManagerModules.default
  ];

  programs.concierge.enable = true;
}
