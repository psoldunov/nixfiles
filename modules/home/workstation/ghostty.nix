# Ghostty on every workstation, from one config so Whopper looks like the
# Macs: Ghostty's stock colors (no theme), a translucent blurred background
# and JetBrainsMono Nerd Font. Whopper installs the nixpkgs build; the Macs
# get the app from the Homebrew cask (modules/darwin/homebrew.nix), so only
# the config is managed there. The font comes from hosts/whopper/modules/
# fonts.nix and the font-jetbrains-mono-nerd-font cask.
#
# Blur on Whopper is KWin's: its global Blur effect decides the strength and
# ignores any per-app intensity.
{
  lib,
  pkgs,
  ...
}: {
  programs.ghostty = {
    enable = true;
    package = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin null;

    settings = {
      background-opacity = 0.7;
      background-blur = true;
      font-family = "JetBrainsMono Nerd Font";
      font-size = 12.5;
      font-style = "bold";
      confirm-close-surface = false;
      window-padding-x = "8,4";
      window-padding-y = 8;
      # Size of every new window, in cells (columns x rows). Tabs and splits
      # keep their window's size.
      window-width = 128;
      window-height = 38;
      # Already the default on Linux; macOS keeps the app running otherwise.
      quit-after-last-window-closed = true;
      # Shift+Enter sends ESC+CR, which Claude Code reads as a newline.
      keybind = "shift+enter=text:\\x1b\\r";
      # Ghostty's TERM, xterm-ghostty, is unknown on hosts without its
      # terminfo (the Macs; Whopper and BigTasty install Ghostty), which
      # breaks clear, less and editors over SSH. The shell integration's ssh
      # wrapper copies the terminfo over with tic on first connect, and falls
      # back to xterm-256color when that fails. The default features stay on.
      shell-integration-features = "ssh-env,ssh-terminfo";
    };
  };
}
