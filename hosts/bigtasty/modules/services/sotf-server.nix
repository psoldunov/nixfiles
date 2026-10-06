{lib, ...}: {
  virtualisation.oci-containers.containers = {
    sotf-server = {
      image = "jammsen/sons-of-the-forest-dedicated-server:latest";
      environment = {
        PUID = "1000";
        PGID = "1000";
        ALWAYS_UPDATE_ON_START = "true";
        SKIP_NETWORK_ACCESSIBILITY_TEST = "true";
        FILTER_SHADER_AND_MESH_AND_WINE_DEBUG = "true";
      };
      ports = [
        "8766:8766/udp"
        "27016:27016/udp"
        "9700:9700/udp"
      ];
      volumes = [
        "/RAID/apps/sotf/game:/sonsoftheforest"
      ];
    };
  };

  # The image exits 0 when SteamCMD gives up on an update, so the default
  # Restart=on-failure left the server dead. The start limit stops a
  # persistent update failure from looping forever; it shows up in
  # `systemctl --failed` instead.
  systemd.services.docker-sotf-server = {
    serviceConfig = {
      Restart = lib.mkForce "always";
      RestartSec = "60s";
    };
    startLimitBurst = 5;
    startLimitIntervalSec = 3600;
  };
}
