{
  lib,
  globalSettings,
  pkgs,
  ...
}: {
  gtk = lib.mkIf globalSettings.enableHyprland {
    enable = true;
    theme = {
      name = "Tokyonight-Dark";
      package = pkgs.tokyonight-gtk-theme;
    };

    cursorTheme = lib.mkIf globalSettings.enableHyprland {
      name = "WhiteSur-cursors";
      package = pkgs.whitesur-cursors;
      size = 24;
    };

    font = lib.mkIf globalSettings.enableHyprland {
      name = "SF Pro Display";
      size = 12;
    };
  };
}
