# macOS-style global shortcuts, with Meta standing in for Cmd.
#
# Only window-manager actions live here. In-app shortcuts (copy, paste, new
# tab) stay on Ctrl — making Meta+C copy needs a keyboard remapper, not
# Plasma. Window snapping follows Rectangle, with Meta+Ctrl standing in for its
# Ctrl+Opt. That takes Meta+Ctrl+arrows away from desktop switching, which keeps
# the stock Ctrl+F1..F4 (only one desktop is configured anyway). macOS's
# Ctrl+Left/Right stays with apps, which use it to jump by word.
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

        # Rectangle, native KWin actions only (no thirds). Stock Meta+arrow,
        # Meta+PgUp and Meta+Backspace bindings are kept alongside. Rectangle's
        # Ctrl+Opt+F (center third) is not bound: Meta+Ctrl+F stays fullscreen.
        # Halves: Ctrl+Opt+arrows.
        "Window Quick Tile Left" = ["Meta+Ctrl+Left" "Meta+Left"];
        "Window Quick Tile Right" = ["Meta+Ctrl+Right" "Meta+Right"];
        "Window Quick Tile Top" = ["Meta+Ctrl+Up" "Meta+Up"];
        "Window Quick Tile Bottom" = ["Meta+Ctrl+Down" "Meta+Down"];
        # Quarters: Ctrl+Opt+U/I/J/K.
        "Window Quick Tile Top Left" = "Meta+Ctrl+U";
        "Window Quick Tile Top Right" = "Meta+Ctrl+I";
        "Window Quick Tile Bottom Left" = "Meta+Ctrl+J";
        "Window Quick Tile Bottom Right" = "Meta+Ctrl+K";
        # Maximize, center, restore: Ctrl+Opt+Return/C/Backspace.
        "Window Maximize" = ["Meta+Ctrl+Return" "Meta+PgUp"];
        "Window Move Center" = "Meta+Ctrl+C";
        "Window Restore" = ["Meta+Ctrl+Backspace" "Meta+Backspace"];
        # Next/previous display: Ctrl+Opt+Cmd+Right/Left.
        "Window to Next Screen" = ["Meta+Ctrl+Alt+Right" "Meta+Shift+Right"];
        "Window to Previous Screen" = ["Meta+Ctrl+Alt+Left" "Meta+Shift+Left"];

        # Stock owners of Meta+Ctrl+arrows, freed for the halves above.
        "Switch One Desktop to the Left" = [];
        "Switch One Desktop to the Right" = [];
        "Switch One Desktop Up" = [];
        "Switch One Desktop Down" = [];
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
