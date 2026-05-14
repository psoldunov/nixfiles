{
  config,
  lib,
  pkgs,
  ...
}: {
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
}
