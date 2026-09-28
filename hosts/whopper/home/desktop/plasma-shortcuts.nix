# macOS-style global shortcuts, with Meta standing in for Cmd.
#
# Only window-manager actions live here. In-app shortcuts (copy, paste, new
# tab) stay on Ctrl — making Meta+C copy needs a keyboard remapper, not
# Plasma. Desktop switching stays on Meta+Ctrl+Left/Right instead of macOS's
# Ctrl+Left/Right, which Linux apps use to jump by word.
#
# plasma-manager merges these into ~/.config/kglobalshortcutsrc at activation;
# kglobalaccel only rereads that file at login, so log out after a rebuild.
# Actions not listed here keep whatever System Settings last wrote.
{
  programs.plasma = {
    shortcuts = {
      # Cmd+Space: Spotlight. KRunner's stock Alt+Space goes to the layout
      # switcher below; its other stock bindings are kept.
      "services/org.kde.krunner.desktop"._launch = ["Meta+Space" "Alt+F2" "Search"];

      # Cycles the layouts set in plasma.nix (programs.plasma.input.keyboard).
      "KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" = ["Alt+Space" "Meta+Alt+K"];

      # New terminal window.
      "services/kitty.desktop"._launch = "Meta+Return";

      kwin = {
        # Cmd+Q. Plasma's stock Meta+Q (activity switcher) is freed below.
        "Window Close" = ["Meta+Q" "Alt+F4"];
        # Cmd+H and Cmd+M.
        "Window Minimize" = ["Meta+H" "Meta+M" "Meta+PgDown"];
        # Cmd+Ctrl+F.
        "Window Fullscreen" = "Meta+Ctrl+F";
        # Cmd+Tab, and Cmd+` to cycle one app's windows.
        "Walk Through Windows" = ["Meta+Tab" "Alt+Tab"];
        "Walk Through Windows (Reverse)" = ["Meta+Shift+Tab" "Alt+Shift+Tab"];
        "Walk Through Windows of Current Application" = ["Meta+`" "Alt+`"];
        "Walk Through Windows of Current Application (Reverse)" = ["Meta+~" "Alt+~"];
        # Cmd+Opt+Esc: force quit.
        "Kill Window" = ["Meta+Alt+Esc" "Meta+Ctrl+Esc"];
      };

      # Cmd+Ctrl+Q.
      ksmserver."Lock Session" = ["Meta+Ctrl+Q" "Meta+L" "Screensaver"];

      plasmashell."manage activities" = [];
    };

    # Cmd+Shift+3/4/5. Each is also bound by its US-layout symbol (Shift+3 is
    # "#"), since a shifted digit can reach kglobalaccel in either form.
    spectacle.shortcuts = {
      captureEntireDesktop = ["Meta+Shift+3" "Meta+#"];
      captureRectangularRegion = ["Meta+Shift+4" "Meta+$"];
      launch = ["Meta+Shift+5" "Meta+%"];
    };
  };
}
