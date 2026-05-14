{
  config,
  lib,
  pkgs,
  pkgs-stable,
  inputs,
  hostConfig,
  ...
}: let
  catppuccinPackage = pkgs.catppuccin-gtk.override {
    accents = ["peach"];
    variant = "mocha";
  };
in {
  imports = [
    inputs.steam-presence.nixosModules.steam-presence
  ];

  # `nixpkgs.config.allow{Unfree,Insecure,Broken}` baseline is set in
  # modules/nixos/nix.nix. Whopper-only knobs: joypixels licensing +
  # additional insecure-package allowlist.
  nixpkgs = {
    config = {
      joypixels.acceptLicense = true;
      allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "joypixels"
        ];
      permittedInsecurePackages = [
        "electron-24.8.6"
        "yubikey-manager-qt-1.2.5"
      ];
    };
  };

  environment.sessionVariables = {
    HSA_OVERRIDE_GFX_VERSION = "11.0.0";
    NIXOS_OZONE_WL = "1";
  };

  # 1password companion browsers registry
  environment.etc = {
    "1password/custom_allowed_browsers" = {
      text = ''
        chromium
        zen
      '';
      mode = "0755";
    };
  };

  # nix-ld, fish, mtr, git baseline live in modules/nixos.
  programs.direnv.enable = true;
  programs.seahorse.enable = true;

  programs = {
    _1password = {
      enable = true;
    };
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = ["psoldunov"];
    };
  };

  programs.steam = {
    enable = true;
    package = pkgs.millennium-steam;
    extest.enable = false;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    platformOptimizations.enable = true;
    localNetworkGameTransfers.openFirewall = true;
    presence = {
      enable = true;
      steamApiKeyFile = config.sops.secrets.STEAM_API_KEY.path;
      userIds = ["76561197995337689"];
      coverArt.steamGridDB = {
        enable = true;
        apiKeyFile = config.sops.secrets.STEAMGRIDDB_API_KEY.path;
      };
    };
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
    args = [
      "-W 3840"
      "-H 2160"
      "-r 120"
      "--hdr-enabled"
      "--adaptive-sync"
      "--force-grab-cursor"
    ];
  };

  programs.gamemode.enable = true;

  programs.nano = {
    enable = true;
    nanorc = ''
      set atblanks
      set autoindent
      set backup
      set boldtext
      set constantshow
      set cutfromcursor
      set indicator
      set linenumbers
      set minibar
      set mouse
      set showcursor
      set softwrap
      set speller "aspell -x -c"
      set trimblanks
      set whitespace "»·"
      set zap
      set multibuffer
      set titlecolor bold,lightwhite,blue
      set promptcolor lightwhite,lightblack
      set statuscolor bold,lightwhite,green
      set errorcolor bold,lightwhite,red
      set spotlightcolor black,lime
      set selectedcolor lightwhite,magenta
      set stripecolor ,yellow
      set scrollercolor cyan
      set numbercolor cyan
      set keycolor cyan
      set functioncolor green
    '';
    syntaxHighlight = true;
  };

  environment.systemPackages =
    (with pkgs; [
      codex
      puppeteer-cli
      typescript
      catppuccinPackage
      abcde
      cddiscid
      libmusicbrainz5
      libmusicbrainz
      monkeysAudio
      libdiscid
      (writeShellScriptBin "gnome-terminal" "exec -a $0 ${pkgs.kitty}/bin/kitty $@")
      appimage-run
      wev
      usbutils
      pciutils
      nixd
      nixpkgs-fmt
      lm_sensors
      bulky
      sops
      alejandra
      dive
      gperftools
      polkit_gnome
      libsecret
      ddcutil
      ddcui
      trashy
      file-roller
      grilo
      grilo-plugins
      sg3_utils
      solaar
      evince
      eog
      simple-scan
      sassc
      bat
      cloudflared
      hyprcursor
      boxbuddy
      distrobox
      distroshelf
      emote
      distrobox-tui
      run
      libdrm
      hwinfo
      iperf
      yubioath-flutter
      yubikey-manager
      gnome-icon-theme
      adwaita-icon-theme
      p7zip
      gnome-themes-extra
      virtio-win
      zenity
      hyprevents
      joypixels
      radeontop
      pkg-config
      thunderbird
      wf-recorder
      tesseract
      hwdata
      pciutils
      cliphist
      webp-pixbuf-loader
      supabase-cli
      kdiskmark
      libwebp
      slurp
      wl-clipboard
      speedcrunch
      dracut
      openssl
      openssl.dev
      imagemagick
      devenv
      libsecret
      (python3.withPackages (p:
        with p; [
          discid
          keyring
          yt-dlp
          musicbrainzngs
          fontforge
        ]))
      gcc
      libheif
      protontricks
      ydotool
      desktop-file-utils
      socat
      mangohud
      vulkan-tools
      devenv
      bottles
      libva-utils
      cargo
      pop
      wishlist
      nvtopPackages.amd
      vhs
      soft-serve
      glow
      skate
      hyprprop
      gum
      rhythmbox
      libgpod
      hfsprogs
      translate-shell
      clang
      cmake
      cmake-format
      cmake-lint
      ccd2iso
      nss
      mkinitcpio-nfs-utils
      libnfs
      libgccjit
      libclang
      gdb
      clang-tools
      gcc
      mkcert
      libadwaita
      dig
      winetricks
      gnome-disk-utility
      dconf-editor
      cabextract
      idevicerestore
      killall
      sbctl
      pavucontrol
      ffmpeg-full
      mpv
      (wrapOBS {
        plugins = with pkgs.obs-studio-plugins; [
          wlrobs
          obs-backgroundremoval
          obs-vkcapture
          obs-pipewire-audio-capture
        ];
      })
      go
      ripgrep
      udiskie
      wlr-randr
      nix-prefetch-scripts
      pamixer
      dualsensectl
      evtest
      trigger-control
      hyprpicker
      awww
      localsend
      pkgs-stable.calibre
      unzip
      woff2
      freetube
      grim
      xdg-utils
      xdg-user-dirs
      php
      libxcrypt
      i2c-tools
      cifs-utils
      tldr
      playerctl
      qdigidoc
      libdigidocpp
      logitech-udev-rules
      tmux
      fastfetch
      papirus-icon-theme
      papirus-folders
      hunspell
      hunspellDicts.ru_RU
      hunspellDicts.en_US
      hunspellDicts.en_GB-ise
      lsd
      yad
      pulseaudio
      logiops
      libnotify
      glib
      sox
      gsettings-desktop-schemas
      kdePackages.qt6ct
      qt5.qtwayland
      gsettings-qt
      keymapp
      kontroll
      libsForQt5.qt5.qtwayland
      kdePackages.qtwayland
      qt6.qmake
      qt6.qtwayland
      jq
      wget
      wlogout
      mpc
      nemo-with-extensions
      keychain
      expressvpn
      nbd
    ])
    ++ (
      if hostConfig.ollamaDocker
      then [
        (pkgs.writeShellScriptBin "ollama" "exec -a $0 docker exec -it ollama ollama $@")
      ]
      else []
    );
}
