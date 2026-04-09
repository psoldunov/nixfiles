{
  inputs,
  pkgs,
  appleFonts,
  hostConfig,
  ...
}: let
  catppuccinPackage = pkgs.catppuccin-gtk.override {
    accents = ["peach"];
    variant = "mocha";
  };
in {
  catppuccin = {
    enable = false;
    accent = "peach";
    flavor = "mocha";
  };

  services.displayManager.sddm.wayland.enable = !hostConfig.enableHyprland;
  services.displayManager.sddm.enable = !hostConfig.enableHyprland;
  services.desktopManager.plasma6.enable = !hostConfig.enableHyprland;

  # Hyprland
  programs.hyprland = {
    enable = hostConfig.enableHyprland;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
  };

  services.hypridle.enable = hostConfig.enableHyprland;
  programs.hyprlock.enable = hostConfig.enableHyprland;
  services.blueman.enable = hostConfig.enableHyprland;

  # Greeter
  programs.regreet = {
    enable = hostConfig.enableHyprland;
    theme = {
      package = pkgs.catppuccin-gtk.override {
        accents = ["peach"];
        size = "standard";
        variant = "mocha";
      };
      name = "catppuccin-mocha-peach-standard";
    };
    font = {
      name = "SF Pro Display";
      size = 12;
      package = appleFonts.sf-pro;
    };
    iconTheme = {
      package = pkgs.pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
    cursorTheme = {
      package = pkgs.catppuccin-cursors.mochaDark;
      name = "catppuccin-mocha-dark-cursors";
    };
    settings = {
      appearance.greeting_msg = "Howdy partner";
      commands = {
        reboot = ["systemctl" "reboot"];
        poweroff = ["systemctl" "poweroff"];
      };
      background = {
        path = "/usr/share/backgrounds/user/lock_background.png";
        fit = "Cover";
      };
      default_session = {
        command = "Hyprland";
        user = "psoldunov";
      };
    };
  };

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
        "text/html" = ["brave-browser.desktop"];
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
        "WebBrowser" = "brave-browser.desktop";
        "x-scheme-handler/http" = "brave-browser.desktop";
        "x-scheme-handler/https" = "brave-browser.desktop";
        "x-scheme-handler/chrome" = "brave-browser.desktop";
        "x-scheme-handler/about" = "brave-browser.desktop";
        "x-scheme-handler/unknown" = "brave-browser.desktop";
        "x-scheme-handler/vscode" = "code-url-handler.desktop";
        "application/x-extension-htm" = "brave-browser.desktop";
        "application/x-extension-html" = "brave-browser.desktop";
        "application/x-extension-shtml" = "brave-browser.desktop";
        "application/xhtml+xml" = "brave-browser.desktop";
        "application/x-extension-xhtml" = "brave-browser.desktop";
        "application/x-extension-xht" = "brave-browser.desktop";
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
            "${pkgs.papirus-icon-theme}/share/icons:ro"
            "${pkgs.catppuccin-cursors.mochaDark}/share/icons:ro"
            "${catppuccinPackage}/share/themes:ro"
            "/run/current-system/sw/share:ro"
            "/mnt/Games/Emulation:rw"
            "/run/current-system/sw/bin/:ro"
          ];
          sockets = ["wayland" "!x11" "!fallback-x11"];
        };

        Environment = {
          ICON_THEME = "Papirus-Dark";
          GTK_THEME = "catppuccin-mocha-peach-standard";
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
  services.gnome = {
    sushi.enable = true;
    gnome-keyring.enable = true;
  };
  services.tumbler.enable = true;
  services.gvfs = {
    enable = true;
    package = pkgs.gvfs;
  };
  services.udisks2.enable = true;

  programs.dconf.enable = true;
}
