{
  config,
  lib,
  pkgs,
  pkgs-stable,
  inputs,
  hostConfig,
  ...
}: {
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
  # Wallet GUI is kdePackages.kwalletmanager, installed by the plasma6 module.

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

  # Upstream module sets WorkingDirectory=%h/.local/state/steam-presence but
  # never creates it, so the unit dies at CHDIR and blocks HM activation.
  # For user units StateDirectory resolves to $XDG_STATE_HOME/<name>.
  systemd.user.services.steam-presence.serviceConfig.StateDirectory = "steam-presence";

  programs.gamescope = {
    enable = true;
    capSysNice = true;
    args = [
      "-W 3840"
      "-H 2160"
      "-r 144"
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

  # GNOME/GTK desktop apps and the Hyprland-era Wayland tools were replaced by
  # their KDE counterparts. Most ship with the plasma6 module: Ark (File
  # Roller), Okular (Evince), Gwenview (Eye of GNOME), the Audio volume applet
  # and settings page (pavucontrol), the Device Notifier (udiskie), the emoji
  # selector (Emote), polkit-kde-agent (polkit_gnome), Spectacle (grim, slurp,
  # wf-recorder), Klipper (cliphist), kscreen-doctor (wlr-randr) and, because
  # hardware.sane is on, Skanpage (Simple Scan). KRename (Bulky) and
  # programs.partition-manager (GNOME Disks, in desktop-environment.nix) are
  # added explicitly.
  # Rhythmbox stays: it is the only player here that syncs iPods through
  # libgpod.
  environment.systemPackages =
    (with pkgs; [
      codex
      puppeteer-cli
      typescript
      kdePackages.breeze-gtk
      abcde
      cddiscid
      libmusicbrainz5
      libmusicbrainz
      monkeysAudio
      libdiscid
      appimage-run
      wev
      usbutils
      pciutils
      nixd
      nixpkgs-fmt
      lm_sensors
      krename
      sops
      alejandra
      dive
      gperftools
      libsecret
      ddcutil
      ddcui
      trashy
      grilo
      grilo-plugins
      sg3_utils
      bat
      cloudflared
      boxbuddy
      distrobox
      distroshelf
      distrobox-tui
      run
      libdrm
      hwinfo
      iperf
      yubioath-flutter
      yubikey-manager
      adwaita-icon-theme
      p7zip
      virtio-win
      zenity
      joypixels
      radeontop
      pkg-config
      thunderbird
      tesseract
      hwdata
      supabase-cli
      kdiskmark
      libwebp
      wl-clipboard
      speedcrunch
      dracut
      openssl
      openssl.dev
      imagemagick
      devenv
      cachix
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
      mkcert
      dig
      winetricks
      cabextract
      idevicerestore
      killall
      sbctl
      ffmpeg-full
      mpv
      (wrapOBS {
        plugins = with pkgs.obs-studio-plugins; [
          obs-backgroundremoval
          obs-vkcapture
          obs-pipewire-audio-capture
        ];
      })
      go
      ripgrep
      nix-prefetch-scripts
      pamixer
      dualsensectl
      evtest
      trigger-control
      localsend
      pkgs-stable.calibre
      unzip
      woff2
      freetube
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
      kdePackages.breeze-icons
      vapor-kde-theme
      nixos-icons
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
      qt5.qtwayland
      keymapp
      kontroll
      kdePackages.qtwayland
      qt6.qmake
      qt6.qtwayland
      jq
      wget
      mpc
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
