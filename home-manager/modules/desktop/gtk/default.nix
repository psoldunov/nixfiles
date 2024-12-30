{
  lib,
  globalSettings,
  pkgs,
  ...
}: let
  catppuccin-gtk-theme = pkgs.catppuccin-gtk.override {
    variant = "mocha";
    accents = ["peach"];
  };
in {
  gtk = lib.mkIf globalSettings.enableHyprland {
    enable = true;
    theme = {
      # name = "catppuccin-mocha-peach-standard";
      # package = catppuccin-gtk-theme;
      name = "Tokyonight-Dark";
      package = pkgs.tokyonight-gtk-theme;
    };
    catppuccin = {
      enable = false;
      icon = {
        enable = true;
        accent = "peach";
        flavor = "mocha";
      };
    };

    cursorTheme = lib.mkIf globalSettings.enableHyprland {
      name = "catppuccin-mocha-dark-cursors";
      # package = pkgs.catppuccin-cursors.mochaDark;
      size = 24;
    };

    font = lib.mkIf globalSettings.enableHyprland {
      name = "SF Pro Display";
      size = 12;
    };
  };

  # home.file = lib.mkIf globalSettings.enableHyprland {
  #   ".config/gtk-4.0/gtk-dark.css" = {
  #     source = "${catppuccin-gtk-theme}/share/themes/catppuccin-mocha-peach-standard/gtk-4.0/gtk-dark.css";
  #   };
  #   ".config/gtk-4.0/assets" = {
  #     source = "${catppuccin-gtk-theme}/share/themes/catppuccin-mocha-peach-standard/gtk-4.0/assets";
  #     recursive = true;
  #   };
  # };
}
