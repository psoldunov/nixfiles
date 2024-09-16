# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  pkgs-stable,
  zen-specific,
  ...
}: let
  systemStateVersion = "23.11";

  scripts = import ./scripts/default.nix {
    pkgs = pkgs;
    config = config;
  };
in {
  imports = [
    ./modules
  ];

  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "peach";
    pointerCursor = {
      enable = true;
      accent = "dark";
      flavor = "mocha";
    };
  };

  services.nextcloud-client = {
    enable = true;
    startInBackground = true;
    package = pkgs-stable.nextcloud-client;
  };

  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

    secrets = {
      ANTHROPIC_API_KEY = {};
      NPM_TOKEN = {};
      RESEND_API_KEY = {};
      OPENAI_API_KEY = {};
      GH_TOKEN = {};
    };
  };

  xdg = {
    mime.enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = ["nemo.desktop" "yazi.desktop"];
        "application/pdf" = ["org.gnome.Papers.desktop" "org.gnome.evince.desktop"];
        "text/html" = ["firefox.desktop"];
        "TerminalEmulator" = "kitty.desktop";
        "image/jpeg" = ["org.gnome.eog.desktop"];
        "image/png" = ["org.gnome.eog.desktop"];
        "image/svg+xml" = ["org.gnome.eog.desktop"];
        "image/gif" = ["org.gnome.eog.desktop"];
        "image/webp" = ["org.gnome.eog.desktop"];
        "video/mp4" = ["mpv.desktop"];
        "video/webm" = ["mpv.desktop"];
        "video/x-matroska" = ["mpv.desktop"];
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/chrome" = "firefox.desktop";
        "application/x-extension-htm" = "firefox.desktop";
        "application/x-extension-html" = "firefox.desktop";
        "application/x-extension-shtml" = "firefox.desktop";
        "application/xhtml+xml" = "firefox.desktop";
        "application/x-extension-xhtml" = "firefox.desktop";
        "application/x-extension-xht" = "firefox.desktop";
      };
      associations = {
        removed = {
          "application/pdf" = ["chromium-browser.desktop"];
        };
      };
    };
  };

  # xdg.desktopEntries = {
  #   "qt5ct.desktop" = {
  #     name = "Qt5 Settings";
  #     noDisplay = true;
  #   };
  # };

  systemd.user.enable = true;

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };

  programs.chromium = {
    enable = true;
    dictionaries = with pkgs; [
      hunspellDictsChromium.en_US
      hunspellDictsChromium.fr_FR
    ];
    extensions = [
      {
        id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";
      }
      {
        id = "dcpihecpambacapedldabdbpakmachpb";
        updateUrl = "https://raw.githubusercontent.com/iamadamdev/bypass-paywalls-chrome/master/updates.xml";
      }
      {
        id = "dbepggeogbaibhgnhhndojpepiihcmeb";
      }
      {
        id = "fmkadmapgofadopljbjfkapdkoienihi";
      }
      {
        id = "mjfibgdpclkaemogkfadpbdfoinnejep";
      }
      {
        id = "mfjbmoaliicmnliefefaagcddnjkjamc";
      }
      {
        id = "jbbplnpkjmmeebjpijfedlgcdilocofh";
      }
    ];
  };

  home.file."${config.xdg.dataHome}/nemo-python/extensions/syncstate-Nextcloud.py" = {
    source = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/psoldunov/nemo-nextcloud/master/usr/share/nemo-python/extensions/syncstate-Nextcloud.py";
      hash = "sha256-o7KnYjo6Hyz8he4gCKEPbv9hDBYXnigGf+MVHRluqeU=";
    };
  };

  programs.hyprlock.enable = true;

  programs.password-store.enable = true;

  programs = {
    home-manager.enable = true;
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowInsecure = true;
  };

  programs.firefox = {
    enable = true;
  };

  home.packages = with pkgs; [
    beets
    bruno
    hyprshade
    rpi-imager
    pkgs-stable.mysql-workbench
    geekbench
    bambu-studio
    deno
    neovim
    nodejs_20
    obsidian
    pywal
    spotify
    mattermost-desktop
    gnome-font-viewer
    rofi-bluetooth
    duckstation
    plex-media-player
    plexamp
    pcsx2
    heroic
    chiaki
    notion-app-enhanced
    appflowy
    ferdium
    steam-rom-manager
    prismlauncher
    ryujinx
    picard
    gimp
    newman
    telegram-desktop
    slack
    protonup-qt
    protonup-ng
    vesktop
    lightly-boehs
    # libsForQt5.lightly
    ookla-speedtest
    catppuccin-cursors
    varia
    zed-editor
    zen-specific
    transmission-remote-gtk
    pantheon.elementary-iconbrowser
    scripts.restart_ags
    scripts.idle_check
    scripts.record_screen
    scripts.grab_screen_text
    scripts.create_screenshot
    scripts.create_screenshot_area
    scripts.kill_gamescope
    scripts.start_static_wallpaper
    scripts.start_video_wallpaper
    scripts.convert_all_to_webp
    scripts.convert_all_to_woff2
    scripts.convert_all_to_mkv
    scripts.update_system
  ];

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      text-scaling-factor = "1.1";
    };
  };

  programs = {
    btop.enable = true;
    htop.enable = true;
  };

  home.file = {
    ".local/share/applications/webflow.desktop" = {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Webflow
        GenericName=Web Editor
        Icon=/home/psoldunov/.icons/webflow.png
        Exec=chromium --new-window --app=https://webflow.com/dashboard?r=1&workspace=boundary-digital-llc %U
        Terminal=false
        Categories=Development;
      '';
    };
    ".local/share/applications/figma.desktop" = {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Figma
        GenericName=Design Tool
        Icon=figma
        Exec=${pkgs.appimage-run}/bin/appimage-run ${config.home.homeDirectory}/Applications/figma-linux_0.11.4_linux_x86_64.AppImage --ozone-platform=wayland
        Terminal=false
        Categories=Development;
      '';
    };
    ".local/share/applications/nixfiles-zed.desktop" = {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Open Nixfiles in Zed
        GenericName=This opens nixfiles in Zed
        Icon=nix-snowflake
        Exec=zed --new /home/psoldunov/.nixfiles
        Terminal=false
      '';
    };
    ".local/share/applications/nixfiles-code.desktop" = {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Open Nixfiles in VS Code
        GenericName=This opens nixfiles in VS Code
        Icon=nix-snowflake
        Exec=code -n /home/psoldunov/.nixfiles
        Terminal=false
      '';
    };
  };

  home.stateVersion = systemStateVersion;
}
