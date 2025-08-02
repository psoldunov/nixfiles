{
  lib,
  globalSettings,
  pkgs,
  config,
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
      package = lib.mkForce pkgs.papirus-icon-theme;
    };

    cursorTheme = lib.mkIf globalSettings.enableHyprland {
      name = "catppuccin-mocha-dark-cursors";
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
    ".config/gtk-3.0/bookmarks" = {
      force = true;
      text = ''
        file:///${config.home.homeDirectory}/Downloads Downloads
        file:///${config.home.homeDirectory}/Projects Projects
        file:///${config.home.homeDirectory}/Documents Documents
        file:///${config.home.homeDirectory}/Music Music
        file:///${config.home.homeDirectory}/Videos Videos
        file:///${config.home.homeDirectory}/Pictures Pictures
        file:///${config.home.homeDirectory}/Nextcloud Nextcloud
        file:///${config.home.homeDirectory}/Sync Sync
      '';
    };
  };
}
