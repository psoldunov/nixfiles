{
  pkgs,
  ...
}: {
  catppuccin.enable = false;

  # KDE Plasma 6 desktop with SDDM as the login manager.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # XDG
  xdg = {
    menus.enable = true;
    icons.enable = true;
    portal.extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    autostart.enable = true;
    sounds.enable = true;
    mime = {
      enable = true;
      defaultApplications = {
        "inode/directory" = ["nemo.desktop" "yazi.desktop"];
        "application/pdf" = ["org.gnome.Papers.desktop" "org.gnome.evince.desktop"];
        "text/html" = ["zen.desktop"];
        "text/*" = ["code.desktop"];
        "TerminalEmulator" = "kitty.desktop";
        "image/jpeg" = ["org.gnome.eog.desktop"];
        "image/png" = ["org.gnome.eog.desktop"];
        "image/svg+xml" = ["org.gnome.eog.desktop"];
        "image/gif" = ["org.gnome.eog.desktop"];
        "image/webp" = ["org.gnome.eog.desktop"];
        "image/avif" = ["org.gnome.eog.desktop"];
        "video/mp4" = ["mpv.desktop"];
        "video/webm" = ["mpv.desktop"];
        "video/x-matroska" = ["mpv.desktop"];
        "x-scheme-handler/magnet" = ["io.github.TransmissionRemoteGtk.desktop"];
        "WebBrowser" = "zen.desktop";
        "x-scheme-handler/http" = "zen.desktop";
        "x-scheme-handler/https" = "zen.desktop";
        "x-scheme-handler/chrome" = "zen.desktop";
        "x-scheme-handler/about" = "zen.desktop";
        "x-scheme-handler/unknown" = "zen.desktop";
        "x-scheme-handler/vscode" = "code-url-handler.desktop";
        "application/x-extension-htm" = "zen.desktop";
        "application/x-extension-html" = "zen.desktop";
        "application/x-extension-shtml" = "zen.desktop";
        "application/xhtml+xml" = "zen.desktop";
        "application/x-extension-xhtml" = "zen.desktop";
        "application/x-extension-xht" = "zen.desktop";
        "application/zip" = "org.gnome.FileRoller.desktop";
        "Email" = "thunderbird.desktop";
        "message/rfc822" = "thunderbird.desktop";
        "x-scheme-handler/mailto" = "thunderbird.desktop";
        "x-scheme-handler/mid" = "thunderbird.desktop";
        "x-scheme-handler/news" = "thunderbird.desktop";
        "x-scheme-handler/snews" = "thunderbird.desktop";
        "x-scheme-handler/nntp" = "thunderbird.desktop";
        "x-scheme-handler/feed" = "thunderbird.desktop";
        "x-scheme-handler/figma" = "figma-linux.desktop";
        "application/rss+xml" = "thunderbird.desktop";
        "application/x-extension-rss" = "thunderbird.desktop";
        "x-scheme-handler/webcal" = "thunderbird.desktop";
        "text/calendar" = "thunderbird.desktop";
        "application/x-extension-ics" = "thunderbird.desktop";
        "x-scheme-handler/webcals" = "thunderbird.desktop";
        "x-scheme-handler/whatsapp" = "whatsie.desktop";
      };
    };
  };

  # Flatpak
  services.flatpak = {
    enable = true;
    update.onActivation = true;
    packages = [
      "com.github.tchx84.Flatseal"
      "com.steamgriddb.SGDBoop"
    ];
    overrides = {
      global = {
        Context = {
          filesystems = [
            "${pkgs.kdePackages.breeze-icons}/share/icons:ro"
            "${pkgs.kdePackages.breeze}/share/icons:ro"
            "${pkgs.kdePackages.breeze-gtk}/share/themes:ro"
            "/run/current-system/sw/share:ro"
            "/mnt/Games/Emulation:rw"
            "/run/current-system/sw/bin/:ro"
          ];
          sockets = ["wayland" "!x11" "!fallback-x11"];
        };

        Environment = {
          ICON_THEME = "breeze-dark";
          GTK_THEME = "Breeze-Dark";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        };
      };
    };
  };

  # X server is disabled (Wayland-only) but xkb keymap still configured
  # for TTY fallback and tools that consult it.
  services.xserver.enable = false;
  services.xserver = {
    xkb.layout = "us";
    xkb.variant = "";
  };
  services.xserver.excludePackages = [pkgs.xterm];

  # Filesystem + desktop plumbing
  # gnome-keyring is deliberately absent: KWallet from the plasma6 module is the
  # Secret Service provider, and enabling both makes pam_gnome_keyring and
  # pam_kwallet start competing daemons for org.freedesktop.secrets.
  services.gnome = {
    sushi.enable = true;
  };
  services.tumbler.enable = true;
  services.gvfs = {
    enable = true;
    package = pkgs.gvfs;
  };
  services.udisks2.enable = true;

  programs.dconf.enable = true;
}
