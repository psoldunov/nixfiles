# Token Station — tray monitor for Claude Code and Codex plan usage, from its
# own flake. Bump it with `nix flake update token-station`.
#
# The module installs the daemon as a supervised systemd user service (also
# D-Bus activatable) plus the Plasma applet, which shows up in the system tray
# by itself. The GNOME extension is left off: this host runs Plasma.
#
# The Claude Code statusline hook feeds live plan usage to the daemon. It
# replaces programs.claude-code.settings.statusLine, so the caveman statusline
# is passed through `wrap` to keep rendering. It repeats the command from
# modules/home/programs/claude-code/settings.nix instead of reading the merged
# option, which would be this module's own override and recurse.
{inputs, ...}: {
  imports = [
    inputs.token-station.homeManagerModules.default
  ];

  programs.token-station = {
    enable = true;
    claudeStatusline = {
      enable = true;
      wrap = ''bash "${inputs.caveman}/src/hooks/caveman-statusline.sh"'';
    };
  };
}
