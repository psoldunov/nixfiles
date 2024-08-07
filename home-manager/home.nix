# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  nixpkgs-stable,
  ...
}: let
  systemStateVersion = "23.11";

  scripts = import ./scripts/default.nix {
    pkgs = pkgs;
    config = config;
  };

  catppuccin-gtk-theme = pkgs.catppuccin-gtk.override {
    variant = "mocha";
    accents = ["peach"];
  };

  pkgs-stable = import nixpkgs-stable {
    system = "x86_64-linux";
  };
in {
  imports = [
    ./modules
    # inputs.ags.homeManagerModules.default
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

  # services.nextcloud-client = {
  #   enable = true;
  #   startInBackground = true;
  #   package = pkgs-stable.nextcloud-client;
  # };

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
    hyprshade
    pkgs-stable.mysql-workbench
    geekbench
    bambu-studio
    deno
    neovim
    nodejs_20
    obsidian
    pywal
    spotify
    bitwarden-desktop
    bitwarden-cli
    mattermost-desktop
    gnome-font-viewer
    rofi-bluetooth
    duckstation
    pcsx2
    heroic
    ferdium
    steam-rom-manager
    prismlauncher
    ryujinx
    gimp
    newman
    telegram-desktop
    slack
    protonup-qt
    protonup-ng
    deluge-gtk
    vesktop
    youtube-dl
    ookla-speedtest
    catppuccin-cursors
    zed-editor
    pantheon.elementary-iconbrowser
    pkgs-stable.nextcloud-client
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

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style = {
      catppuccin.enable = false;
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
    ".local/share/applications/postman.desktop" = {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Postman
        GenericName=API Editor
        Icon=postman
        Exec=chromium --new-window --app=https://web.postman.co/workspaces %U
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
        Exec=chromium --new-window --app=https://www.figma.com/files/ %U
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
  };

  home.stateVersion = systemStateVersion;
}
