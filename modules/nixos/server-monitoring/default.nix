# Server-only: explicitly imported by BigTasty and BigKing, never the desktop baseline.
{
  config,
  lib,
  pkgs,
  ...
}: let
  isNas = config.networking.hostName == "BigKing";
  textDir = "/var/lib/server-monitoring";
  commonUnits = [
    "sshd"
    "docker"
    "docker-watchtower"
    "mdmonitor"
    "nfs-server"
    "nfs-mountd"
    "samba-smbd"
    "samba-nmbd"
    "samba-wsdd"
    "prometheus-node-exporter"
  ];
  hostUnits =
    if isNas
    then [
      "avahi-daemon"
      "smartd"
      "asustor-fan"
      "asustor-leds"
      "openlcmd"
      "syncthing"
    ]
    else [
      "nginx"
      "cloudflare-dyndns"
      "netatalk"
      "nbd-server"
      "sonarr"
      "radarr"
      "lidarr"
      "prowlarr"
      "seerr"
      "jellyfin"
      "plex"
      "flaresolverr"
      "uptime-kuma"
      "syncthing"
      "vaultwarden"
      "concierge-server"
      "grafana"
      "prometheus"
      "prometheus-blackbox-exporter"
      "sharesSync"
      "immichSync"
    ];
  # A host running the household DNS server (modules/nixos/home-dns).
  dnsUnits = lib.optionals config.services.adguardhome.enable [
    "adguardhome"
    "unbound"
  ];
  containerUnits = map (c: c.serviceName) (
    builtins.attrValues config.virtualisation.oci-containers.containers
  );
  tunnelUnits = map (name: "cloudflared-tunnel-${name}") (
    builtins.attrNames config.services.cloudflared.tunnels
  );
  scheduled =
    [
      "docker-image-prune"
      "server-intel-gpu-sample"
    ]
    ++ lib.optionals (!isNas) ["media-audio-fix"];
  units = lib.unique (commonUnits ++ hostUnits ++ dnsUnits ++ containerUnits ++ tunnelUnits ++ scheduled);
  inventory = pkgs.writeText "server-monitoring-inventory.prom" (
    lib.concatMapStrings (name: ''
      server_expected_unit_info{name="${name}.service",mode="${
        if builtins.elem name scheduled
        then "scheduled (inactive = idle)"
        else "continuous"
      }"} 1
    '')
    units
  );
in {
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = lib.mkDefault "127.0.0.1";
    openFirewall = false;
    enabledCollectors = [
      "systemd"
      "textfile"
    ];
    extraFlags = [
      "--collector.textfile.directory=${textDir}"
      "--collector.systemd.unit-include=(${
        lib.concatStringsSep "|" (map (name: "${lib.escapeRegex name}[.]service") units)
      })"
      # Only physical root/data filesystems: do not count NFS, binds or Docker overlays twice.
      "--collector.filesystem.mount-points-exclude=^/(dev|proc|sys|run|export|mnt|var/lib/docker)($|/)"
    ];
  };

  users.groups.server-monitoring = {};
  users.users.server-monitoring = {
    isSystemUser = true;
    group = "server-monitoring";
    extraGroups = [
      "video"
      "render"
    ];
  };
  # Only this service can write textfiles; exporter has read-only world-readable metrics.
  systemd.tmpfiles.rules = ["d ${textDir} 0755 server-monitoring server-monitoring -"];
  systemd.services.server-monitoring-inventory = {
    description = "Publish expected service inventory (including absent units)";
    wantedBy = ["multi-user.target"];
    before = ["prometheus-node-exporter.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    restartTriggers = [inventory];
    script = ''
      install -m 0644 ${inventory} ${textDir}/.inventory.tmp
      mv -f ${textDir}/.inventory.tmp ${textDir}/inventory.prom
    '';
  };
  systemd.services.server-intel-gpu-sample = {
    description = "Bounded Intel engine busy sampler for node exporter";
    serviceConfig = {
      Type = "oneshot";
      User = "server-monitoring";
      Group = "server-monitoring";
      SupplementaryGroups = [
        "video"
        "render"
      ];
      ExecStart = "${pkgs.python3}/bin/python3 ${./intel-gpu-sample.py} --output ${textDir}/intel-gpu.prom --intel-gpu-top ${pkgs.intel-gpu-tools}/bin/intel_gpu_top --timeout-seconds 5";
      TimeoutStartSec = "12s";
      AmbientCapabilities = ["CAP_PERFMON"];
      CapabilityBoundingSet = ["CAP_PERFMON"];
      DeviceAllow = ["char-drm rw"];
      DevicePolicy = "closed";
      PrivateDevices = false;
      PrivateUsers = false;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ReadWritePaths = [textDir];
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      NoNewPrivileges = true;
      LockPersonality = true;
      RestrictSUIDSGID = true;
      RestrictRealtime = true;
      RestrictAddressFamilies = ["AF_UNIX"];
      SystemCallArchitectures = "native";
      SystemCallFilter = [
        "@system-service"
        "perf_event_open"
      ];
      UMask = "0022";
    };
  };
  systemd.timers.server-intel-gpu-sample = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "15s";
      AccuracySec = "1s";
    };
  };
}
