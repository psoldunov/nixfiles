# Clokkr — tray time tracker in Rust and GPUI, from its own flake.
# Bump it with `nix flake update clokkr`.
#
# The flake builds the locked master commit from source, so the first build
# after a bump compiles the whole workspace. The module installs the package
# (`clokkrd`, the `clokkr` CLI and the `clokkr-app` tray app), runs the daemon
# as the systemd user unit `clokkrd.service` with the graphical session, and
# starts `clokkr-app --hidden` at login. The daemon unit is keep-old, so a
# switch never stops a running timer; the new build takes over at the next
# login or after `systemctl --user restart clokkrd`.
#
# The Plasma widget only links the plasmoid; add "Clokkr Timer" to a panel
# from Edit Mode › Add Widgets.
#
# `clokkr mcp` serves the timer, tasks, sessions and reports to Claude Code,
# Codex and pi over stdio (docs/mcp.md in the Clokkr repo).
{
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.clokkr.homeManagerModules.default
  ];

  programs.clokkr = {
    enable = true;
    plasmaWidget.enable = true;
  };

  programs.mcp.servers.clokkr = {
    command = "${config.programs.clokkr.package}/bin/clokkr";
    args = ["mcp"];
  };
}
