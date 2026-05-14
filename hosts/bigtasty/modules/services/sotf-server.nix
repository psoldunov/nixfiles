{...}: {
  virtualisation.oci-containers.containers = {
    sotf-server = {
      image = "jammsen/sons-of-the-forest-dedicated-server:latest";
      environment = {
        PUID = "1000";
        PGID = "1000";
        ALWAYS_UPDATE_ON_START = "true";
        SKIP_NETWORK_ACCESSIBILITY_TEST = "true";
        FILTER_SHADER_AND_MESH = "true";
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
}
