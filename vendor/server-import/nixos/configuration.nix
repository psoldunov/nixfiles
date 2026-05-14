# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  pkgs-stable,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./modules/immich.nix
    ./modules/paperless.nix
    ./modules/karakeep.nix
    ./modules/syncthing.nix
    ./modules/sotf-server.nix
    ./modules/n8n.nix
    ./modules/nocodb.nix
    ./modules/vaultwarden.nix
    ./modules/infisical.nix
  ];

  fileSystems."/RAID" = {
    device = "/dev/disk/by-uuid/4d2aef16-e69c-46aa-8552-3d0c1289c7f3";
    fsType = "ext4";
  };

  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/psoldunov/.config/sops/age/keys.txt";

    secrets = {
      SLSKD_ENV = {
        group = "docker";
      };
      JELLYPLEX_ENV = {
        group = "docker";
      };
      CFDYNDNS_TOKEN = {
        owner = "psoldunov";
      };
      CFDYNDNS_API_KEY = {
        owner = "psoldunov";
      };
      CF_DNS_CREDS = {
        group = "acme";
      };
      OPENAI_API_KEY = {
        group = "docker";
      };
      CFD_MAIN_TUNNEL = {
        owner = "cloudflared";
      };
      N8N_SETTINGS = {
        owner = "psoldunov";
      };
      PAPERLESS_SETTINGS = {
        group = "docker";
      };
      HOMARR_SETTINGS = {
        group = "docker";
      };
      IMMICH_SETTINGS = {};
      KARAKEEP_SETTINGS = {};
      NOCODB_SETTINGS = {
        group = "docker";
      };
      TRANSMISSION = {
        group = "docker";
      };
      CLAWDBOT_TELEGRAM_BOT_TOKEN = {
        owner = "psoldunov";
      };
      VAULTWARDEN_SETTINGS = {
        owner = "vaultwarden";
      };
      INFISICAL_SETTINGS = {
        group = "docker";
      };
    };
  };

  services.fwupd.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.swraid = {
    enable = true;
    mdadmConf = ''
      MAILADDR philipp@theswisscheese.com
    '';
  };

  environment.sessionVariables = {
    MAILADDR = "philipp@theswisscheese.com";
    LIBVA_DRIVER_NAME = "iHD";
  };

  boot.initrd.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  boot.blacklistedKernelModules = ["nouveau" "nvidia"];

  programs.fish.enable = true;

  networking = {
    hostName = "BigTasty";
    defaultGateway = "10.24.24.1";
    nameservers = [
      "10.24.24.9"
    ];
    wireless = {
      enable = false; # Enables wireless support via wpa_supplicant.
      networks = {
        "Flying Tiger Dojo" = {
          psk = "U2qsWznpDKzUAk";
        };
      };
    };
    interfaces = {
      eno2.useDHCP = true;
      wl01.useDHCP = true;
      enp8s0.ipv4.addresses = [
        {
          address = "10.24.24.2";
          prefixLength = 24;
        }
      ];
    };
  };

  nix = {
    settings = {
      warn-dirty = false;
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
    };
  };

  powerManagement.powertop.enable = true;

  systemd.services = {
    sharesSync = {
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        ExecStart = pkgs.writeShellScript "shares-immich" ''
          SRC="/RAID/shares"
          DEST="/mnt/Backup"

          while ${pkgs.inotify-tools}/bin/inotifywait -r -e modify,create,delete,move $SRC; do
              ${pkgs.rsync}/bin/rsync -av --delete $SRC $DEST
          done
        '';
        User = "root";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };
  };

  services.udev = {
    extraRules = ''
      ACTION=="add", ATTRS{idProduct}=="1500", ATTRS{idVendor}=="05ac", DRIVERS=="usb", RUN+="${pkgs.sg3_utils}/bin/sg_raw %r/sr%n EA 00 00 00 00 00 01"
    '';
  };

  services.nbd.server = {
    enable = true;
    exports.cdrom = {
      path = "/dev/sr0";
      extraOptions = {
        readonly = true;
      };
    };
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
      intel-compute-runtime
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-vaapi-driver
    ];
  };

  hardware.intel-gpu-tools.enable = true;

  services.cachefilesd = {
    enable = true;
    cacheDir = "/RAID/cachefilesd";
  };

  # Set your time zone.
  time.timeZone = "Asia/Nicosia";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  fileSystems."/mnt/Media" = {
    device = "10.24.24.3:/volume1/Media";
    fsType = "nfs";
    options = ["rw" "fsc" "nolock" "nconnect=16"];
  };

  fileSystems."/mnt/Backup" = {
    device = "10.24.24.3:/volume1/Backup";
    fsType = "nfs";
    options = ["rw" "fsc" "nolock"];
  };

  fileSystems."/mnt/Games" = {
    device = "10.24.24.3:/volume1/Games";
    fsType = "nfs";
    options = ["rw" "fsc" "nolock"];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    users = {
      psoldunov = {
        isNormalUser = true;
        shell = pkgs.fish;
        description = "Philipp Soldunov";
        extraGroups = ["wheel" "docker" "libvirtd" "video" "media"]; # Enable ‘sudo’ for the user.
        packages = with pkgs; [];
      };
    };
    extraUsers = {
      cloudflared = {
        isSystemUser = true;
        group = "cloudflared";
      };
    };
  };

  users.groups = {
    media = {
      gid = 1777;
      members = [];
    };
    cloudflared = {};
  };

  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowInsecure = true;
      allowBroken = true;
      permittedInsecurePackages = [
        "aspnetcore-runtime-wrapped-6.0.36"
        "aspnetcore-runtime-6.0.36"
        "dotnet-sdk-wrapped-6.0.428"
        "dotnet-sdk-6.0.428"
      ];
    };
    overlays = [];
  };

  environment.systemPackages = with pkgs; [
    claude-code
    bun
    pnpm
    ghostty
    sops
    thunderbolt
    syncthing
    usbutils
    pciutils
    alejandra
    vscode
    nodejs
    ffmpeg-full
    htop
    trashy
    vdpauinfo
    libva-utils
    bat
    lm_sensors
    btop
    lsd
    mdadm
    glib
    nixd
    iperf
    distrobox-tui
    distrobox
    fzf
    libheif
    nvtopPackages.intel
    libavif
    cloudflared
    libvdpau
    imagemagick
    neovim
    wget
    yazi
    (
      pkgs.writeShellScriptBin "update_system" ''
        cd /etc/nixos
        git add .
        git commit -am "pre-update commit $(date '+%d/%m/%Y %H:%M:%S')"
        sudo nix flake update
        sudo nixos-rebuild switch --show-trace --upgrade-all
      ''
    )
    (
      pkgs.writeShellScriptBin "clean_system" ''
        sudo nix-collect-garbage -d
        nix-collect-garbage -d
        docker image prune -a -f
      ''
    )
    (
      pkgs.writeShellScriptBin "rebuild_system" ''
        cd /etc/nixos
        git add .
        git commit -am "rebuild commit $(date '+%d/%m/%Y %H:%M:%S')"
        sudo nixos-rebuild switch --show-trace
      ''
    )
    fastfetch
    (python3.withPackages (p:
      with p; [
        pygobject3
        gst-python
        numpy
        pyinotify
        pip
        mutagen
        poetry-core
        sentencepiece
      ]))
  ];

  services.nginx = {
    enable = true;
    appendHttpConfig = ''
      proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=20g inactive=60m use_temp_path=off;
    '';
    virtualHosts = {
      "sonarr.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = ''
          client_max_body_size 500000M;
        '';
        locations."/" = {
          proxyPass = "http://localhost:8989";
          proxyWebsockets = true;
        };
      };
      "lidarr.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = ''
          client_max_body_size 500000M;
        '';
        locations."/" = {
          proxyPass = "http://localhost:8686";
          proxyWebsockets = true;
        };
      };
      "prowlarr.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:9696";
          proxyWebsockets = true;
        };
      };
      "radarr.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = ''
          client_max_body_size 500000M;
        '';
        locations."/" = {
          proxyPass = "http://localhost:7878";
          proxyWebsockets = true;
        };
      };
      "portainer.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "https://localhost:9443";
          proxyWebsockets = true;
        };
      };
      "kuma.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:3001";
          proxyWebsockets = true;
        };
      };
      "jellyseerr.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:5055";
          proxyWebsockets = true;
        };
      };
      "homarr.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:7575";
          proxyWebsockets = true;
        };
      };
      "syncthing.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = ''
          client_max_body_size 50000M;
        '';
        locations."/" = {
          proxyPass = "http://localhost:8384";
          proxyWebsockets = true;
        };
      };
      "adguard.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://10.24.24.9:80";
          proxyWebsockets = true;
        };
      };
      "jellyfin.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:8096";
        };
      };
      "immich.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = ''
          client_max_body_size 50000M;
          proxy_read_timeout 600s;
          proxy_send_timeout 600s;
          send_timeout 600s;
        '';
        locations."/" = {
          proxyPass = "http://localhost:2283";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host              $host;
            proxy_set_header X-Real-IP         $remote_addr;
            proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_redirect off;
          '';
        };
      };
      "homeassistant.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:8123";
          proxyWebsockets = true;
        };
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      dnsProvider = "cloudflare";
      email = "philipp@theswisscheese.com";
      environmentFile = config.sops.secrets.CF_DNS_CREDS.path;
    };
    certs = {
      "sonarr.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "radarr.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "lidarr.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "prowlarr.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "jellyseerr.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "kuma.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "syncthing.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "homeassistant.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "jellyfin.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "immich.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "homarr.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "portainer.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "adguard.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
    };
  };

  services.cloudflared = {
    enable = true;
    tunnels = {
      "CFD_MAIN_TUNNEL" = {
        credentialsFile = config.sops.secrets.CFD_MAIN_TUNNEL.path;
        default = "http_status:404";
        ingress = {
          "search.theswisscheese.com" = {
            service = "http://localhost:9080";
          };
        };
      };
    };
  };

  services.cloudflare-dyndns = {
    enable = true;
    proxied = true;
    apiTokenFile = config.sops.secrets.CFDYNDNS_TOKEN.path;
    domains = [
      "kuma.theswisscheese.com"
      "syncthing.theswisscheese.com"
      "jellyfin.theswisscheese.com"
      "immich.theswisscheese.com"
      "homeassistant.theswisscheese.com"
      "prowlarr.theswisscheese.com"
      "sotf.theswisscheese.com"
      "portainer.theswisscheese.com"
    ];
  };

  # started in user sessions.
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.iperf3 = {
    enable = true;
    openFirewall = true;
  };

  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  services.radarr = {
    enable = true;
    openFirewall = true;
    user = "psoldunov";
    group = "users";
  };

  services.lidarr = {
    enable = true;
    openFirewall = true;
    user = "psoldunov";
    group = "users";
  };

  services.sonarr = {
    enable = true;
    openFirewall = true;
    user = "psoldunov";
    group = "users";
  };

  services.seerr = {
    enable = true;
    openFirewall = true;
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  virtualisation = {
    docker = {
      enable = true;
      enableOnBoot = true;
    };
    libvirtd.enable = true;
    containerd.enable = true;
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      JellyPlex-Watched = {
        image = "luigi311/jellyplex-watched:latest";
        environmentFiles = [
          config.sops.secrets.JELLYPLEX_ENV.path
        ];
        environment = {
          SYNC_FROM_PLEX_TO_JELLYFIN = "True";
          SYNC_FROM_JELLYFIN_TO_PLEX = "True";
          PLEX_BASEURL = "http://10.24.24.3:32400";
          JELLYFIN_BASEURL = "http://10.24.24.2:8096";
          USER_MAPPING = ''{ "psoldunov": "Philipp Soldunov" }'';
          LIBRARY_MAPPING = ''{ "Shows": "TV Shows" }'';
          WHITELIST_USERS = "psoldunov,Philipp Soldunov";
        };
      };
      slskd = {
        image = "slskd/slskd";
        volumes = [
          "/RAID/apps/slskd:/app"
          "/mnt/Media:/Media"
        ];
        user = "1000:100";
        environment = {
          SLSKD_REMOTE_CONFIGURATION = "true";
          SLSKD_SHARED_DIR = "/Media/Music";
          SLSKD_NO_AUTH = "true";
          ASPNETCORE_HTTP_PORTS = "7080";
        };
        environmentFiles = [
          config.sops.secrets.SLSKD_ENV.path
        ];
        extraOptions = [
        ];
        ports = [
          "5030:5030"
          "5031:5031"
          "50300:50300"
        ];
      };
      transmission = {
        image = "lscr.io/linuxserver/transmission:latest";
        environment = {
          PUID = "1000";
          PGID = "100";
          TZ = "Asia/Nicosia";
          WHITELIST = "10.24.24.*,172.17.0.1";
        };
        volumes = [
          "/RAID/apps/transmission/config:/config"
          "/RAID/apps/transmission/downloads:/downloads"
          "/RAID/apps/transmission/watch:/watch"
        ];
        extraOptions = [
        ];
        ports = [
          "9091:9091"
          "51413:51413"
          "51413:51413/udp"
        ];
      };
      homeassistant = {
        volumes = ["/RAID/apps/homeassistant:/config"];
        environment.TZ = "Asia/Nicosia";
        image = "ghcr.io/home-assistant/home-assistant:latest";
        extraOptions = [
          "--network=host"
        ];
        devices = [
          "/dev/serial/by-id/usb-SONOFF_SONOFF_Dongle_Plus_MG24_d043ba8df99aef1182a6af9061ce3355-if00-port0"
        ];
      };
      portainer-ce = {
        image = "portainer/portainer-ce:latest";
        ports = [
          "8000:8000"
          "9443:9443"
        ];
        environment = {
          TRUSTED_ORIGINS = "portainer.theswisscheese.com";
        };
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "portainer_data:/data"
        ];
      };
      homarr = {
        image = "ghcr.io/ajnart/homarr:latest";
        ports = [
          "7575:7575"
        ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "./homarr/appdata:/appdata"
        ];
        environmentFiles = [
          config.sops.secrets.HOMARR_SETTINGS.path
        ];
      };
      watchtower = {
        image = "nickfedor/watchtower:latest";
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
        ];
        environment = {
          TZ = "Asia/Nicosia";
          WATCHTOWER_SCHEDULE = "0 0 4 * * *";
          WATCHTOWER_CLEANUP = "true";
        };
      };
      searxng = {
        image = "searxng/searxng:latest";
        volumes = [
          "/RAID/apps/searxng:/etc/searxng"
        ];
        extraOptions = [];
        ports = ["9080:8080"];
        environment = {
          BASE_URL = "https://search.theswisscheese.com/";
          INSTANCE_NAME = "The Search Cheese";
        };
      };
    };
  };

  boot.kernel.sysctl = {
    "vm.overcommit_memory" = lib.mkForce 1;
  };

  system.activationScripts.dockerNetworks = let
    dockercli = "${config.virtualisation.docker.package}/bin/docker";
    networks = [
      "immich-network"
      "paperless-network"
      "nocodb-network"
      "infisical-network"
    ];
    networks_str = lib.concatStringsSep " " networks;
  in ''
    # Create required networks if missing
    for network in ${networks_str}; do
      check=$(${dockercli} network ls --format "{{.Name}}" | grep -w "$network" || true)
      if [ -z "$check" ]; then
        ${dockercli} network create "$network"
        echo "$network was created."
      else
        echo "$network already exists in docker"
      fi
    done

    # Remove unused custom networks (not default, not in list, no containers)
    for net in $(${dockercli} network ls --format "{{.Name}}" | grep -v -E '^(bridge|host|none)$'); do
      # Skip if in required list
      echo "${networks_str}" | grep -wq "$net" && continue
      # Check if network has containers
      attached=$(${dockercli} network inspect "$net" --format '{{json .Containers}}' | grep -v '{}')
      if [ -z "$attached" ]; then
        echo "Removing unused network: $net"
        ${dockercli} network rm "$net" || { echo "Failed to remove $net"; true; }
      fi
    done
  '';

  services.uptime-kuma = {
    enable = true;
    settings = {
      PORT = "3001";
    };
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  programs.chromium.enable = true;

  fileSystems."/export/transmission" = {
    device = "/RAID/apps/transmission/downloads/complete";
    fsType = "none";
    options = ["bind"];
  };

  fileSystems."/export/slskd" = {
    device = "/RAID/apps/slskd/downloads";
    fsType = "none";
    options = ["bind"];
  };

  fileSystems."/export/Paperless" = {
    device = "/RAID/apps/paperless/consumption";
    fsType = "none";
    options = ["bind"];
  };

  fileSystems."/export/Files" = {
    device = "/RAID/shares/Files";
    fsType = "none";
    options = ["bind"];
  };

  fileSystems."/export/Documents" = {
    device = "/RAID/shares/Documents";
    fsType = "none";
    options = ["bind"];
  };

  services.nfs.server = {
    enable = true;
    exports = ''
      /export/transmission 10.24.24.5(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure) 10.24.24.6(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure) 10.24.24.88(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure)
      /export/slskd 10.24.24.5(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure) 10.24.24.6(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure) 10.24.24.88(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure)
      /export/Files 10.24.24.5(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure) 10.24.24.6(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure) 10.24.24.88(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure)
      /export/Documents 10.24.24.5(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure)
      /export/Paperless 10.24.24.5(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure) 10.24.24.6(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure) 10.24.24.88(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure)
    '';
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "the_server";
        "netbios name" = "BigTasty";
        "security" = "user";
        "hosts allow" = "10.24.24. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
        "vfs objects" = "fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
        "fruit:veto_appledouble" = "no";
        "fruit:nfs_aces" = "no";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles" = "yes";
        "fruit:posix_rename" = "yes";
      };
      "Documents" = {
        "path" = " /export/Documents";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "psoldunov";
        "force group" = "users";
      };
      "Files" = {
        "path" = " /export/Files";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "psoldunov";
        "force group" = "users";
      };
      "SLSKD" = {
        "path" = " /export/slskd";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "psoldunov";
        "force group" = "users";
      };
      "Paperless" = {
        "path" = " /export/Paperless";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "psoldunov";
        "force group" = "users";
      };
      "Transmission" = {
        "path" = " /export/transmission";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "psoldunov";
        "force group" = "users";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  systemd.services."mdmonitor".environment = {
    MDADM_MONITOR_ARGS = "--scan --syslog";
  };

  services.netatalk = {
    enable = true;
    settings = {
      "transmission" = {
        path = "/export/transmission";
        "read only" = false;
      };
      "slskd" = {
        path = "/export/slskd";
        "read only" = false;
      };
      "Files" = {
        path = "/export/Files";
        "read only" = false;
      };
      "Documents" = {
        path = "/export/Documents";
        "read only" = false;
      };
    };
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.AllowUsers = ["psoldunov"];
  };

  networking.firewall.enable = true;
  networking.firewall.allowPing = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [8076 28981 9966 6432 8086 8888 8889 8766 27016 9700 3212 6443 111 2049 2222 3060 4000 4001 4002 4024 5030 9099 5031 50300 32500 4355 20048 53 80 443 2342 8123 11434 3005 8001 9091];
  networking.firewall.allowedUDPPorts = [53 28981 9966 8766 6432 32500 27016 9700 8086 6443 111 2222 2049 11434 4000 4024 4001 4355 4002 20048];

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?
}
