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
      name = "catppuccin-mocha-peach-standard";
      package = catppuccin-gtk-theme;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = lib.mkIf globalSettings.enableHyprland {
      name = "catppuccin-mocha-dark-cursors";
      size = lib.mkForce 16;
    };

    font = lib.mkIf globalSettings.enableHyprland {
      name = "SF Pro Display";
      size = 12;
    };
  };

  home.file = {
    ".config/gtk-4.0/gtk-dark.css" = {
      source = "${catppuccin-gtk-theme}/share/themes/catppuccin-mocha-peach-standard/gtk-4.0/gtk-dark.css";
    };
    ".config/gtk-4.0/assets" = {
      source = "${catppuccin-gtk-theme}/share/themes/catppuccin-mocha-peach-standard/gtk-4.0/assets";
      recursive = true;
    };
  };
}
