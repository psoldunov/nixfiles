# Token Station — tray monitor for Claude Code and Codex plan usage, from its
# own flake. Bump it with `nix flake update token-station`.
#
# The module installs the daemon as a supervised systemd user service (also
# D-Bus activatable) plus the Plasma applet, which shows up in the system tray
# by itself. The GNOME extension is left off: this host runs Plasma.
#
# The Claude Code statusline hook feeds live plan usage to the daemon and sets
# programs.claude-code.settings.statusLine.
{inputs, ...}: {
  imports = [
    inputs.token-station.homeManagerModules.default
  ];

  programs.token-station = {
    enable = true;
    claudeStatusline.enable = true;
  };
}
