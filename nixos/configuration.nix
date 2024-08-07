# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
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

  i686pkgs = pkgs.pkgsi686Linux;
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  catppuccin = {
    enable = true;
    accent = "peach";
    flavor = "mocha";
  };

  console = {
    catppuccin.enable = false;
    earlySetup = true;
    font = "${pkgs.terminus_font}/share/consolefonts/ter-132n.psf.gz";
    packages = with pkgs; [terminus_font];
    keyMap = "us";
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = false;
  boot.initrd.systemd.dbus.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.plymouth = {
    enable = true;
    catppuccin.enable = false;
    theme = "pedro-raccoon";
    themePackages = with pkgs; [
      pedro-raccoon-plymouth
    ];
  };
  boot.loader.grub = {
    catppuccin.enable = false;
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = true;
    gfxmodeEfi = "1920x1080x32";
  };

  nix = {
    settings = {
      warn-dirty = false;
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
      substituters = ["https://cache.nixos.org/" "https://nix-gaming.cachix.org"];
      trusted-public-keys = ["nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="];
    };
  };

  boot.kernelModules = ["uinput" "uhid"];

  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback
  ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';

  boot.kernelParams = ["quiet"];

  services.rpcbind.enable = true;

  programs.regreet = {
    enable = true;
    settings = {
      background = {
        path = "/usr/share/backgrounds/user/lock_background.png";
        fit = "Cover";
      };
      GTK = {
        application_prefer_dark_theme = true;
        icon_theme_name = "Papirus";
        theme_name = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-standard";
        font_name = "SF Pro Display 12";
      };

      commands = {
        reboot = ["systemctl" "reboot"];
        poweroff = ["systemctl" "poweroff"];
      };
    };
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
      libva
      vaapiVdpau
      libvdpau-va-gl
      libGL
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.libvdpau-va-gl
    ];
  };

  services.xserver.videoDrivers = ["amdgpu"];

  boot.swraid.enable = true;
  boot.swraid.mdadmConf = "MAILADDR=philipp@theswisscheese.com";

  programs.hyprland = {
    enable = true;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  environment.sessionVariables = {
    GPERFTOOLS32_PATH = "${i686pkgs.gperftools}";
    GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
  };

  services.mpd = {
    enable = true;
    musicDirectory = "/mnt/Media/Music";
    startWhenNeeded = true;
    network.listenAddress = "any";
    user = "psoldunov";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire"
      }
    '';
  };

  xdg = {
    menus.enable = true;
    icons.enable = true;
    autostart.enable = true;
    sounds.enable = true;
    mime = {
      enable = true;
      defaultApplications = {
        "application/pdf" = "firefox.desktop";
        "text/html" = "firefox.desktop";
        "inode/directory" = "nemo.desktop";
        "TerminalEmulator" = "kitty.desktop";
      };
    };
    portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
    };
  };

  systemd.services.mpd.environment = {
    # https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/609
    XDG_RUNTIME_DIR = "/run/user/1000"; # User-id 1000 must match above user. MPD will look inside this directory for the PipeWire socket.
  };

  hardware = {
    openrazer = {
      enable = true;
      users = ["psoldunov"];
      batteryNotifier.enable = true;
    };
    logitech = {
      wireless = {
        enable = true;
        enableGraphical = true;
      };
    };
    sane.enable = true;
    bluetooth = {
      enable = true;
    };
    uinput.enable = true;
    xone.enable = true;
    i2c.enable = true;
  };

  # Set your time zone.
  time.timeZone = "Europe/Tallinn";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  services.gnome = {
    sushi.enable = true;
    gnome-keyring.enable = true;
  };

  services.tumbler.enable = true;

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_IE.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = false;

  # Configure keymap in X11
  services.xserver = {
    xkb.layout = "us";
    xkb.variant = "";
  };

  # Enable CUPS to print documents.

  services.expressvpn.enable = true;

  services.flatpak.enable = true;

  services.gvfs = {
    enable = true;
  };

  services.udisks2.enable = true;
  services.blueman.enable = true;

  virtualisation = {
    docker.enable = true;
    docker.enableOnBoot = true;
    libvirtd.enable = true;
    containerd.enable = true;
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      agent = {
        image = "portainer/agent:2.19.5";
        ports = [
          "9001:9001"
        ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "/var/lib/docker/volumes:/var/lib/docker/volumes"
        ];
      };
    };
  };

  virtualisation.arion = {
    backend = "docker";
  };

  programs.direnv.enable = true;
  programs.seahorse.enable = true;

  services.xserver.excludePackages = [pkgs.xterm];

  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # █▀█ █▀█ █▀█ █▀▀ █▀█ ▄▀█ █▀▄▀█ █▀
  # █▀▀ █▀▄ █▄█ █▄█ █▀▄ █▀█ █░▀░█ ▄█

  # Fish shell
  programs.fish.enable = true;

  # 1password
  programs = {
    _1password.enable = true;
    _1password-gui = {
      package = pkgs._1password-gui-beta;
      enable = true;
      # Certain features, including CLI integration and system authentication support,
      # require enabling PolKit integration on some desktop environments (e.g. Plasma).
      polkitPolicyOwners = ["psoldunov"];
    };
  };

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureUsers = [
      {
        name = "psoldunov";
      }
    ];
    ensureDatabases = [
      "psoldunov"
    ];
  };

  environment.etc = {
    "1password/custom_allowed_browsers" = {
      text = ''
        firefox
        brave
        chromium
      '';
      mode = "0755";
    };
  };

  # █▄░█ █ ▀▄▀ █▀█ █▄▀ █▀▀ █▀   ▄▀█ █▄░█ █▀▄   █▀█ █░█ █▀▀ █▀█ █░░ ▄▀█ █▄█ █▀
  # █░▀█ █ █░█ █▀▀ █░█ █▄█ ▄█   █▀█ █░▀█ █▄▀   █▄█ ▀▄▀ ██▄ █▀▄ █▄▄ █▀█ ░█░ ▄█

  nixpkgs = {
    config = {
      joypixels.acceptLicense = true;
      allowUnfree = true;
      allowInsecure = true;
      rocmSupport = true;
      allowBroken = true;
      allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "joypixels"
        ];
      permittedInsecurePackages = ["python-2.7.18.6" "electron-24.8.6" "python3.12-youtube-dl-2021.12.17"];
      packageOverrides = pkgs: {
        allowUnfreePredicate = pkg:
          builtins.elem (lib.getName pkg) [
            "steam"
            "steam-original"
            "steam-runtime"
          ];
      };
    };
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  nixpkgs.overlays = [
    (import ./overlays/hyprevents.nix)
    (import ./overlays/hyprprop.nix)
    (import ./overlays/vscode.nix)
    (import ./overlays/plymouth-pedro.nix)
    (import ./overlays/globalprotect-openconnect_git.nix)
  ];

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

  # █▀▀ █▀█ █▄░█ ▀█▀ █▀
  # █▀░ █▄█ █░▀█ ░█░ ▄█

  fonts.packages = with pkgs; [
    roboto
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    comic-neue
    comic-mono
    ibm-plex
    # (nerdfonts.override {fonts = ["JetBrainsMono"];})
  ];

  # █░█ ▄▀█ █▀█ █▀▄ █░█░█ ▄▀█ █▀█ █▀▀   ▄▀█ █▄░█ █▀▄   █▀█ █▀█ █ █▄░█ ▀█▀ █▀▀ █▀█ █▀
  # █▀█ █▀█ █▀▄ █▄▀ ▀▄▀▄▀ █▀█ █▀▄ ██▄   █▀█ █░▀█ █▄▀   █▀▀ █▀▄ █ █░▀█ ░█░ ██▄ █▀▄ ▄█

  hardware.keyboard.qmk.enable = true;

  services.ddccontrol.enable = true;

  programs.dconf.enable = true;

  # Enable sound with pipewire.
  # sound.enable = true;
  hardware.pulseaudio.enable = false;

  # Enable the pipewire service.
  services.pipewire = {
    enable = true;
    wireplumber.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;
    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
    lowLatency = {
      # enable this module
      enable = true;
      # defaults (no need to be set unless modified)
      quantum = 64;
      rate = 48000;
    };
  };

  # Udev for Apple Superdrive
  services.udev = {
    packages = [
      pkgs.yubikey-personalization
    ];
    extraRules = ''
      ACTION=="add", ATTRS{idProduct}=="1500", ATTRS{idVendor}=="05ac", DRIVERS=="usb", RUN+="${pkgs.sg3_utils}/bin/sg_raw %r/sr%n EA 00 00 00 00 00 01"

      # ACTION=="remove", ENV{ID_BUS}=="usb", ENV{ID_MODEL_ID}=="0407", ENV{ID_VENDOR_ID}=="1050", ENV{ID_VENDOR}=="Yubico", RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
    '';
  };

  # Printing
  services.printing = {
    enable = true;
    cups-pdf.enable = true;
    drivers = with pkgs; [hplipWithPlugin];
  };

  hardware.printers = {
    ensurePrinters = [
      {
        name = "HP_LaserJet_MFP_M28w_9B18D8";
        location = "Office";
        deviceUri = "http://10.24.24.229:631";
        model = "drv:///hp/hpcups.drv/hp-laserjet_pro_mfp_m27cnw.ppd";
        ppdOptions = {
          PageSize = "A4";
        };
      }
    ];
    ensureDefaultPrinter = "HP_LaserJet_MFP_M28w_9B18D8";
  };

  # █▀ █▄█ █▀ ▀█▀ █▀▀ █▀▄▀█   █▀█ ▄▀█ █▀▀ █▄▀ ▄▀█ █▀▀ █▀▀ █▀
  # ▄█ ░█░ ▄█ ░█░ ██▄ █░▀░█   █▀▀ █▀█ █▄▄ █░█ █▀█ █▄█ ██▄ ▄█

  programs.nix-ld.dev.enable = true;

  services.fwupd.enable = true;

  environment.systemPackages = with pkgs; [
    globalprotect-openconnect_git
    (writeShellScriptBin "gnome-terminal" "exec -a $0 kitty $@")
    appimage-run
    wev
    usbutils
    pciutils
    nixd
    nixpkgs-fmt
    vscode
    sops
    alejandra
    podman-tui
    podman-compose
    dive
    gperftools
    swww
    via
    rhythmbox
    polkit_gnome
    libsecret
    ddcutil
    ddcui
    trashy
    file-roller
    grilo
    grilo-plugins
    kitty
    sg3_utils
    libsForQt5.kdenlive
    libsForQt5.qt5ct
    glaxnimate
    solaar
    kitty-img
    kitty-themes
    sassc
    bat
    cloudflared
    hyprcursor
    linux-firmware
    libgcc
    fzf
    (catppuccin-gtk.override {
      accents = ["${config.catppuccin.accent}"];
      variant = "${config.catppuccin.flavor}";
    })
    wget
    evince
    shotwell
    simple-scan
    speedcrunch
    gparted
    zstd
    audacity
    distrobox
    boxbuddy
    qpaeq
    run
    iperf
    kdePackages.qt6ct
    yubikey-manager-qt
    yubikey-manager
    virt-manager
    # telegram-desktop_git
    gnome-icon-theme
    adwaita-icon-theme
    gnome-themes-extra
    hyprevents
    joypixels
    radeontop
    pkg-config
    thunderbird
    wf-recorder
    tesseract
    hwdata
    pciutils
    brave
    cliphist
    webp-pixbuf-loader
    libwebp
    slurp
    wl-clipboard
    openssl
    openssl.dev
    imagemagick
    libsecret
    # (python3.withPackages (p:
    #   with p; [
    #     pygobject3
    #     gst-python
    #     numpy
    #     pyinotify
    #     pip
    #     mutagen
    #     setuptools
    #     gguf
    #     poetry-core
    #     sentencepiece
    #     openai-whisper
    #     srt
    #   ]))
    gcc
    protontricks
    ydotool
    desktop-file-utils
    poetry
    socat
    mangohud
    vulkan-tools
    zoxide
    jellyfin-media-player
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
    typst
    typstfmt
    typst-lsp
    translate-shell
    typst-live
    nss
    mkinitcpio-nfs-utils
    libnfs
    mkcert
    libadwaita
    winetricks
    wineWowPackages.full
    gnome-disk-utility
    dconf-editor
    cabextract
    killall
    sbctl
    pavucontrol
    ffmpeg-full
    mpv
    (wrapOBS {
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-backgroundremoval
        obs-pipewire-audio-capture
        obs-vkcapture
      ];
    })
    go
    ripgrep
    udiskie
    wlr-randr
    nix-prefetch-scripts
    pamixer
    hyprpicker
    hyprpaper
    swayidle
    corepack
    swaylock
    localsend
    calibre
    unzip
    woff2
    grim
    xdg-utils
    pass
    xdg-user-dirs
    php
    libxcrypt
    i2c-tools
    cifs-utils
    tldr
    playerctl
    qdigidoc
    libdigidocpp
    xwaylandvideobridge
    logitech-udev-rules
    tmux
    fastfetch
    papirus-icon-theme
    papirus-folders
    libreoffice-fresh
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
    gsettings-qt
    libsForQt5.qt5.qtwayland
    kdePackages.qtwayland
    qt6.qmake
    qt6.qtwayland
    jq
    wget
    wlogout
    mpc-cli
    nemo-with-extensions
    keychain
    yubioath-flutter
    expressvpn
  ];

  systemd.user.services.mpris-proxy = {
    description = "Mpris proxy";
    after = ["network.target" "sound.target"];
    wantedBy = ["default.target"];
    serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
  };

  # █▀▀ ▄▀█ █▀▄▀█ █ █▄░█ █▀▀
  # █▄█ █▀█ █░▀░█ █ █░▀█ █▄█

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    platformOptimizations.enable = true;
    package = pkgs.steam.override {
      extraEnv = {};
      extraLibraries = pkgs:
        with pkgs; [
          xorg.libXcursor
          xorg.libXi
          xorg.libXinerama
          xorg.libXScrnSaver
          libpng
          libpulseaudio
          libvorbis
          stdenv.cc.cc.lib
          libkrb5
          keyutils
        ];
    };
  };

  programs.gamemode.enable = true;

  services.sunshine = {
    enable = true;
    openFirewall = true;
    autoStart = false;
  };

  # █▄░█ █▀▀ ▀█▀ █░█░█ █▀█ █▀█ █▄▀ █ █▄░█ █▀▀   ▄▀█ █▄░█ █▀▄   █▀ █▀▀ █▀▀ █░█ █▀█ █ ▀█▀ █▄█
  # █░▀█ ██▄ ░█░ ▀▄▀▄▀ █▄█ █▀▄ █░█ █ █░▀█ █▄█   █▀█ █░▀█ █▄▀   ▄█ ██▄ █▄▄ █▄█ █▀▄ █ ░█░ ░█░

  networking.hostName = "Whopper";

  # Network stuff
  networking = {
    defaultGateway = "10.24.24.1";
    nameservers = [
      #"1.1.1.1"
      "10.24.24.9"
    ];
  };

  # 10gbps card
  networking.interfaces.enp8s0.ipv4.addresses = [
    {
      address = "10.24.24.5";
      prefixLength = 24;
    }
  ];

  # Wifi Card

  networking.wireless = {
    enable = false;
    environmentFile = config.sops.secrets."wireless.env".path;
    networks = {
      "@home_uuid@" = {
        psk = "@home_psk@";
      };
    };
  };

  networking.interfaces.wlp7s0.useDHCP = true;

  # Built-in card
  networking.interfaces.enp6s0.useDHCP = true;

  # Networking firewall configuration.
  networking.firewall = {
    allowedTCPPorts = [22 8384 3000 3333 22000 9001 5173 4567 11434 5201 53317 47984 27040 47989 47990 48010 27036 27037];
    allowedUDPPorts = [27031 27032 27033 27034 27035 27036 3000 3333 22000 21027 53317 47998 47999 48000 27031 27036];
  };

  # Disable network manager
  networking.networkmanager.enable = false;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      AllowUsers = ["psoldunov"];
    };
  };

  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/psoldunov/.config/sops/age/keys.txt";

    secrets = {
      "wireless.env" = {};
      # CFD_OLLAMA_TUNNEL = {
      #   owner = "cloudflared";
      # };
    };
  };

  # Cloudflare Tunnels
  services.cloudflared = {
    enable = true;
    user = "cloudflared";
    # tunnels = {
    #   "ollama-tunnel" = {
    #     credentialsFile = config.sops.secrets.CFD_OLLAMA_TUNNEL.path;
    #     default = "http_status:404";
    #     originRequest = {
    #       httpHostHeader = "localhost:11434";
    #     };
    #     ingress = {
    #       "ollama.theswisscheese.com" = {
    #         service = "http://localhost:11434";
    #       };
    #     };
    #   };
    # };
  };

  # Syncthing
  services.syncthing = {
    enable = true;
    user = "psoldunov";
    relay.enable = true;
    dataDir = "/home/psoldunov/"; # Default folder for new synced folders
    configDir = "/home/psoldunov/.config/syncthing";
    settings.gui = {
      user = "psoldunov";
      password = "fbw7PAB8vej1zah!vjq";
    };
    settings.options = {
      urAccepted = -1;
      relaysEnabled = true;
    };
    overrideFolders = false;
    overrideDevices = false;
  };

  # Security
  services.pcscd.enable = true;

  security = {
    polkit.enable = true;
    polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            subject.user == "psoldunov" &&
            action.lookup("unit") == "ollama.service" &&
            (action.lookup("verb") == "start" || action.lookup("verb") == "stop")) {
          return polkit.Result.YES;
        }
      });
    '';
    rtkit.enable = true;
    pam = {
      yubico = {
        enable = true;
        debug = true;
        mode = "challenge-response";
        id = ["19662979"];
      };
      services = {
        hyprlock = {};
        login.u2fAuth = true;
        sudo.u2fAuth = true;
      };
    };
  };

  # Certificates
  security.pki.certificateFiles = ["${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"];

  # █▀ █▀▀ █▀█ █░█ █ █▀▀ █▀▀ █▀
  # ▄█ ██▄ █▀▄ ▀▄▀ █ █▄▄ ██▄ ▄█

  services.locate.enable = true;

  services.ollama = {
    enable = true;
    acceleration = "rocm";
    host = "0.0.0.0";
    rocmOverrideGfx = "11.0.0";
    environmentVariables = {
      OLLAMA_ORIGINS = "app://obsidian.md*";
      HSA_OVERRIDE_GFX_VERSION = "11.0.0";
    };
  };

  # █░█ █▀ █▀▀ █▀█ █▀
  # █▄█ ▄█ ██▄ █▀▄ ▄█

  # My user
  users.users.psoldunov = {
    isNormalUser = true;
    description = "Philipp Soldunov";
    extraGroups = ["networkmanager" "disk" "wheel" "i2c" "video" "storage" "libvirtd" "scanner" "lp" "deluge" "input"];
    shell = pkgs.fish;
  };

  # █▀ █▄█ █▀ ▀█▀ █▀▀ █▀▄▀█   █▀ ▀█▀ ▄▀█ ▀█▀ █▀▀   █░█ █▀▀ █▀█ █▀ █ █▀█ █▄░█
  # ▄█ ░█░ ▄█ ░█░ ██▄ █░▀░█   ▄█ ░█░ █▀█ ░█░ ██▄   ▀▄▀ ██▄ █▀▄ ▄█ █ █▄█ █░▀█

  system.stateVersion = systemStateVersion;
}
