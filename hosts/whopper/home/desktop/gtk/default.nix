{
  lib,
  pkgs,
  config,
  ...
}: {
  # Stock KDE GTK theming: Breeze widget theme + Breeze icons/cursor so GTK
  # apps match the Plasma Breeze desktop.
  gtk = {
    enable = true;

    theme = {
      name = "Breeze-Dark";
      package = pkgs.kdePackages.breeze-gtk;
    };

    gtk4.theme = {
      name = "Breeze-Dark";
      package = pkgs.kdePackages.breeze-gtk;
    };

    iconTheme = {
      name = "breeze-dark";
      package = lib.mkForce pkgs.kdePackages.breeze-icons;
    };

    cursorTheme = {
      name = "breeze_cursors";
      package = pkgs.kdePackages.breeze;
    };
  };

  home.file = {
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
