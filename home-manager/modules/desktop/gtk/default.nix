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

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = lib.mkIf globalSettings.enableHyprland {
      name = "catppuccin-mocha-dark-cursors";
      package = pkgs.catppuccin-cursors.mochaDark;
      size = 24;
    };

    font = lib.mkIf globalSettings.enableHyprland {
      name = "SF Pro Display";
      size = 12;
    };
  };
}
