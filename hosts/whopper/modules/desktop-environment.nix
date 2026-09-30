{pkgs, ...}: {
  # Explicit autoEnable silences the upcoming-default warning; the global
  # toggle stays off so no port applies.
  catppuccin = {
    enable = false;
    autoEnable = false;
  };

  # KDE Plasma 6 desktop with SDDM as the login manager.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # XDG. The portal backends (kde, gtk, kwallet, plasmanotify) and their
  # kde-portals.conf routing come from the plasma6 module.
  xdg = {
    menus.enable = true;
    icons.enable = true;
    autostart.enable = true;
    sounds.enable = true;
    mime = {
      enable = true;
      defaultApplications = import ../mime-defaults.nix;
    };
  };

  # KDE Partition Manager (replaces GNOME Disks). The module also registers
  # kpmcore's D-Bus helper and polkit actions, which a bare package lacks.
  programs.partition-manager.enable = true;

  # KDE Connect (phone integration). The module installs kdeconnect-kde, which
  # Plasma autostarts, and opens TCP/UDP 1714-1764 for discovery and transfers.
  programs.kdeconnect.enable = true;

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
  # Thumbnails and previews come from KIO (kdegraphics-thumbnailers,
  # ffmpegthumbs), so the Nemo-era sushi/tumbler services are gone. gvfs stays
  # for GTK apps: their file dialogs use it for trash, MTP and network shares.
  services.gvfs = {
    enable = true;
    package = pkgs.gvfs;
  };
  services.udisks2.enable = true;

  programs.dconf.enable = true;
}
