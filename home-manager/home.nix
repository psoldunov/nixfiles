# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  config,
  pkgs,
  lib,
  inputs,
  globalSettings,
  pkgs-stable,
  ...
}: let
  systemStateVersion = "23.11";

  scripts = import ./scripts {
    pkgs = pkgs;
    config = config;
    globalSettings = globalSettings;
  };

  figma-appimage = pkgs.fetchurl {
    url = "https://github.com/Figma-Linux/figma-linux/releases/download/v0.11.5/figma-linux_0.11.5_linux_x86_64.AppImage";
    sha256 = "19vkjc2f3h61zya757dnq4rij67q8a2yb0whchz27z7r0aqfa3pr";
  };
in {
  imports = [
    ./modules
  ];

  services.nextcloud-client = {
    enable = true;
    startInBackground = true;
  };

  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

    secrets = {
      SHELL_SECRETS = {};
    };
  };

  xdg.desktopEntries = {
    spotify = {
      name = "Spotify";
      genericName = "Music Player";
      icon = "spotify-client";
      exec = "${config.programs.spicetify.spicedSpotify}/bin/spotify --ozone-platform=x11 %U";
      terminal = false;
      mimeType = ["x-scheme-handler/spotify"];
      categories = ["Audio" "Music" "Player" "AudioVideo"];
    };
    webflow = {
      name = "Webflow";
      genericName = "Web Editor";
      icon = ./modules/desktop/assets/webflow.png;
      exec = ''${pkgs.brave}/bin/brave --profile-directory=Default --new-window --app="https://webflow.com/dashboard?r=1&workspace=boundary-digital-llc" %U'';
      terminal = false;
      mimeType = ["x-scheme-handler/webflow"];
      categories = ["Development"];
    };
    figma = {
      name = "Figma";
      genericName = "Design Tool";
      icon = "figma";
      exec = ''${pkgs.brave}/bin/brave --profile-directory=Default --new-window --app="https://www.figma.com/files" %U'';
      terminal = false;
      mimeType = ["x-scheme-handler/figma"];
      categories = ["Graphics"];
    };
    memos = {
      name = "Memos";
      genericName = "Notes Manager";
      icon = pkgs.fetchurl {
        url = "https://memos.theswisscheese.com/logo.webp";
        sha256 = "+HpE+5YdMqHOzj0AcXKJtKMPZSjGGmeF0Jfk/qspGFk=";
      };
      exec = ''${pkgs.brave}/bin/brave --profile-directory=Default --new-window --app="https://memos.theswisscheese.com" %U'';
      terminal = false;
      mimeType = ["x-scheme-handler/memos"];
      categories = ["Office"];
    };
    motrix = {
      name = "Motrix";
      genericName = "Download Manager";
      exec = "${pkgs.motrix}/bin/motrix --ozone-platform-hint=auto --no-sandbox %U";
      terminal = false;
      icon = "motrix";
      comment = "A full-featured download manager";
      mimeType = [
        "application/x-bittorrent"
        "x-scheme-handler/magnet"
        "application/x-bittorrent"
        "x-scheme-handler/mo"
        "x-scheme-handler/motrix"
        "x-scheme-handler/magnet"
        "x-scheme-handler/thunder"
      ];
      categories = ["Network"];
    };
    # figma = {
    #   name = "Figma";
    #   genericName = "Design Tool";
    #   icon = "figma";
    #   exec = ''${pkgs.appimage-run}/bin/appimage-run ${figma-appimage} --ozone-platform=wayland %U'';
    #   terminal = false;
    #   comment = "Unofficial desktop application for linux";
    #   mimeType = ["x-scheme-handler/figma"];
    #   categories = ["Graphics"];
    # };
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
    package = pkgs.brave;
    dictionaries = with pkgs; [
      hunspellDictsChromium.en_US
      hunspellDictsChromium.fr_FR
      hunspellDictsChromium.de_DE
    ];
    extensions = [
      {
        id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";
      }
      {
        id = "bnomihfieiccainjcjblhegjgglakjdd";
      }
      {
        id = "padekgcemlokbadohgkifijomclgjgif";
      }
      {
        id = "oladmjdebphlnjjcnomfhhbfdldiimaf";
        updateUrl = "https://raw.githubusercontent.com/libredirect/browser_extension/refs/heads/master/src/updates/updates.xml";
      }
      {
        id = "lkbebcjgcmobigpeffafkodonchffocl";
        updateUrl = "https://raw.githubusercontent.com/bpc-clone/bypass-paywalls-chrome-clean/master/updates.xml";
      }
      {
        id = "dbepggeogbaibhgnhhndojpepiihcmeb";
      }
      {
        id = "bkkmolkhemgaeaeggcmfbghljjjoofoh";
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
      {
        id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
      }
      {
        id = "eljapbgkmlngdpckoiiibecpemleclhh";
      }
      {
        id = "djlkbfdlljbachafjmfomhaciglnmkgj";
      }
      {
        id = "gebbhagfogifgggkldgodflihgfeippi";
      }
    ];
  };

  home.file."${config.xdg.dataHome}/nemo-python/extensions/syncstate-Nextcloud.py" = {
    source = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/psoldunov/nemo-nextcloud/master/usr/share/nemo-python/extensions/syncstate-Nextcloud.py";
      hash = "sha256-o7KnYjo6Hyz8he4gCKEPbv9hDBYXnigGf+MVHRluqeU=";
    };
  };

  programs.password-store.enable = true;

  programs = {
    home-manager.enable = true;
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowInsecure = true;
  };

  programs.firefox = {
    enable = false;
  };

  programs.spicetify = let
    spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
  in {
    enable = true;
    #  enabledExtensions = with spicePkgs.extensions; [
    #    adblock
    #    hidePodcasts
    #    shuffle # shuffle+ (special characters are sanitized out of extension names)
    #  ];
    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha";
  };

  home.packages =
    (with pkgs; [
      # whatsapp-for-linux
      zapzap
      electrum
      ledger-live-desktop
      beets
      bruno
      shortwave
      hyprshade
      rpi-imager
      mysql-workbench
      postman
      geekbench
      deno
      neovim
      zoom-us
      nodejs_23
      obsidian
      pywal
      # spotify
      mattermost-desktop
      gnome-font-viewer
      rofi-bluetooth
      duckstation
      plexamp
      pcsx2
      heroic
      shipments
      ferdium
      lollypop
      jamesdsp
      steam-rom-manager
      mediawriter
      prismlauncher
      ryujinx
      picard
      telegram-desktop
      slack
      code-cursor
      protonup-qt
      teams-for-linux
      protonup-ng
      via
      rpcs3
      catppuccin-cursors
      ookla-speedtest
      (discord-canary.override {
        withOpenASAR = true;
        withVencord = true;
      })
      motrix
      zed-editor
      transmission-remote-gtk
      (
        pkgs.writeScriptBin "hello-world" ''
          #!${pkgs.bun}/bin/bun
          console.log("hello world!");
        ''
      )
    ])
    ++ (with scripts; [
      kill_gamescope
      convert_all_to_webp
      convert_all_to_woff2
      convert_all_to_mkv
      update_system
      rebuild_system
      make_timed_commit
      clean_system
      restart_steam
    ])
    ++ (
      if globalSettings.enableHyprland
      then
        (with scripts; [
          grab_screen_text
          record_screen
          restart_ags
          fix_xdph
          idle_check
          start_static_wallpaper
          start_video_wallpaper
          create_screenshot
          create_screenshot_area
        ])
      else []
    );

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      cursor-theme = "catppuccin-mocha-dark-cursors";
      cursor-size = 24;
      text-scaling-factor = "1";
    };
  };

  programs = {
    btop.enable = true;
    htop.enable = true;
  };

  home.file = {
    ".local/share/applications/nixfiles-zed.desktop" = {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Open Nixfiles in Zed
        GenericName=This opens nixfiles in Zed
        Icon=nix-snowflake
        Exec=zeditor --new /home/psoldunov/.nixfiles
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
    ".local/share/applications/nixfiles-bigtasty.desktop" = {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Open SERVER Nixfiles in VS Code
        GenericName=This opens SERVER nixfiles in VS Code
        Icon=nix-snowflake
        Exec=code -n --folder-uri vscode-remote://ssh-remote+10.24.24.2/home/psoldunov/.nixfiles
        Terminal=false
      '';
    };
    ".local/share/applications/nixfiles-nugget.desktop" = {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Open NUGGET Nixfiles in VS Code
        GenericName=This opens NUGGET nixfiles in VS Code
        Icon=nix-snowflake
        Exec=code -n --folder-uri vscode-remote://ssh-remote+10.24.24.7/home/psoldunov/.nixfiles
        Terminal=false
      '';
    };
  };

  home.stateVersion = systemStateVersion;
}
