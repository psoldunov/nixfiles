{
  lib,
  config,
  pkgs,
  ...
}: let
  catppuccin-gtk-theme = pkgs.catppuccin-gtk.override {
    variant = "mocha";
    accents = ["peach"];
  };
in {
  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-mocha-peach-standard";
      package = catppuccin-gtk-theme;
    };
    catppuccin = {
      enable = false;
      icon = {
        enable = true;
        accent = "peach";
        flavor = "mocha";
      };
    };

    cursorTheme = {
      name = "catppuccin-mocha-dark-cursors";
      package = pkgs.catppuccin-cursors.mochaDark;
      size = 24;
    };

    font = {
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
