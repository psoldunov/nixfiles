{
  config,
  lib,
  pkgs,
  pkgs-stable,
  inputs,
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
        chrome
        zen
      '';
      mode = "0755";
    };
  };

  # nix-ld, fish, mtr, git baseline live in modules/nixos; direnv in
  # modules/home/workstation.
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
  environment.systemPackages = with pkgs; [
    codex
    puppeteer-cli
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
    lm_sensors
    krename
    gperftools
    libsecret
    ddcutil
    ddcui
    trashy
    grilo
    grilo-plugins
    sg3_utils
    boxbuddy
    distrobox
    distroshelf
    distrobox-tui
    run
    libdrm
    hwinfo
    yubioath-flutter
    adwaita-icon-theme
    virtio-win
    zenity
    joypixels
    radeontop
    hwdata
    kdiskmark
    wl-clipboard
    speedcrunch
    dracut
    openssl.dev
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
    # Applies SteamGridDB artwork to Steam. Its sgdb:// handler is set in
    # hosts/whopper/mime-defaults.nix.
    sgdboop
    ydotool
    desktop-file-utils
    mangohud
    vulkan-tools
    libva-utils
    nvtopPackages.amd
    rhythmbox
    libgpod
    hfsprogs
    clang
    ccd2iso
    nss
    mkinitcpio-nfs-utils
    libnfs
    libgccjit
    libclang
    gdb
    winetricks
    cabextract
    idevicerestore
    killall
    sbctl
    mpv
    (wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        obs-backgroundremoval
        obs-vkcapture
        obs-pipewire-audio-capture
      ];
    })
    pamixer
    dualsensectl
    evtest
    trigger-control
    localsend
    calibre
    xdg-utils
    xdg-user-dirs
    libxcrypt
    i2c-tools
    cifs-utils
    playerctl
    qdigidoc
    libdigidocpp
    logitech-udev-rules
    fastfetch
    kdePackages.breeze-icons
    vapor-kde-theme
    nixos-icons
    hunspell
    hunspellDicts.ru_RU
    hunspellDicts.en_US
    hunspellDicts.en_GB-ise
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
    mpc
    keychain
    expressvpn
    nbd
  ];
}
