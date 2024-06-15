# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: let
  systemStateVersion = "23.11";

  customObsidian = pkgs.callPackage ./packages/obsidian.nix {};

  catppuccinGtkMochaBlue = pkgs.catppuccin-gtk.override {
    accents = ["blue"];
    variant = "mocha";
  };

  catppuccinKvantumMochaGreen = pkgs.catppuccin-kvantum.override {
    accent = "Green";
    variant = "Mocha";
  };

  scripts = import ./scripts/default.nix {
    pkgs = pkgs;
    config = config;
  };
in {
  imports = [
    ./modules
  ];

  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

    secrets = {
      NPM_TOKEN = {};
      RESEND_API_KEY = {};
      OPENAI_API_KEY = {};
      GH_TOKEN = {};
    };
  };

  systemd.user.enable = true;

  programs.nix-index.enable = true;

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
  };

  home.packages = with pkgs; [
    deno
    nodejs_latest
    customObsidian
    pywal
    spotify
    gnome.gnome-font-viewer
    rofi-bluetooth
    duckstation
    pcsx2
    heroic
    ferdium
    steam-rom-manager
    prismlauncher
    ryujinx
    postman
    newman
    telegram-desktop
    slack
    nextcloud-client
    # (discord.override {
    #   withVencord = true;
    # })
    vesktop
    scripts.idle_check
    scripts.record_screen
    scripts.grab_screen_text
    scripts.create_screenshot
    scripts.create_screenshot_area
    scripts.kill_gamescope
    scripts.start_static_wallpaper
    scripts.start_video_wallpaper
    scripts.hello_world
  ];

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      text-scaling-factor = "1.1";
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.catppuccin-cursors.mochaDark;
    name = "catppuccin-mocha-dark-cursors";
    size = 24;
  };

  gtk = {
    enable = true;
    theme = {
      name = "Catppuccin-Mocha-Standard-Blue-Dark";
      package = catppuccinGtkMochaBlue;
    };

    font = {
      name = "SF Pro Display";
      size = 10;
    };

    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
  };

  # Extra home files
  home.file = {
    ".config/gtk-4.0/gtk-dark.css" = {
      source = "${catppuccinGtkMochaBlue}/share/themes/Catppuccin-Mocha-Standard-Blue-Dark/gtk-4.0/gtk-dark.css";
    };

    ".config/gtk-4.0/assets" = {
      recursive = true;
      source = "${catppuccinGtkMochaBlue}/share/themes/Catppuccin-Mocha-Standard-Blue-Dark/gtk-4.0/assets";
    };
  };

  home.stateVersion = systemStateVersion;
}
