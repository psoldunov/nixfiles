{
  config,
  pkgs,
  ...
}: {
  # services.cloudflared.tunnels."CFD_MAIN_TUNNEL".ingress = {
  #   "immich.theswisscheese.com" = {
  #     service = "http://localhost:2283";
  #   };
  # };

  virtualisation.oci-containers.containers = {
    immich_server = {
      image = "ghcr.io/immich-app/immich-server:release";
      volumes = [
        "/RAID/apps/immich/uploads:/usr/src/app/upload:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
      environmentFiles = [
        config.sops.secrets.IMMICH_SETTINGS.path
      ];
      extraOptions = [
        "--device=/dev/dri:/dev/dri"
        "--network=immich-network"
      ];
      hostname = "immich-server";
      ports = ["2283:2283"];
      dependsOn = ["immich_redis" "immich_postgres"];
      autoStart = true;
    };
    immich_machine_learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:release-openvino";
      volumes = [
        "model-cache:/cache"
        "/dev/bus/usb:/dev/bus/usb"
      ];
      environmentFiles = [
        config.sops.secrets.IMMICH_SETTINGS.path
      ];
      hostname = "immich-machine-learning";
      extraOptions = [
        "--device=/dev/dri:/dev/dri"
        "--device-cgroup-rule=c 189:* rmw"
        "--network=immich-network"
        "--net-alias=immich-machine-learning"
        "--net-alias=immich_machine_learning"
      ];
      autoStart = true;
    };
    immich_redis = {
      image = "docker.io/redis:6.2-alpine@sha256:e3b17ba9479deec4b7d1eeec1548a253acc5374d68d3b27937fcfe4df8d18c7e";
      autoStart = true;
      extraOptions = [
        "--net-alias=redis"
        "--net-alias=immich_redis"
        "--network=immich-network"
      ];
    };
    immich_postgres = {
      image = "docker.io/tensorchord/pgvecto-rs:pg14-v0.2.0@sha256:90724186f0a3517cf6914295b5ab410db9ce23190a2d9d0b9dd6463e3fa298f0";
      environment = {
        POSTGRES_INITDB_ARGS = "--data-checksums";
      };
      environmentFiles = [
        config.sops.secrets.IMMICH_SETTINGS.path
      ];
      hostname = "postgres";
      extraOptions = [
        "--network=immich-network"
        "--net-alias=database"
        "--net-alias=immich_postgres"
        "--net-alias=immich-postgres"
      ];
      volumes = [
        "/RAID/apps/immich/postgres:/var/lib/postgresql/data"
      ];
      cmd = [
        "postgres"
        "-c"
        "shared_preload_libraries=vectors.so"
        "-c"
        ''search_path="$$user", public, vectors''
        "-c"
        "logging_collector=on"
        "-c"
        "max_wal_size=2GB"
        "-c"
        "shared_buffers=512MB"
        "-c"
        "wal_compression=on"
      ];
      autoStart = true;
    };
  };

  security.acme.certs = {
    "immich.theswisscheese.com" = {
      webroot = null;
      dnsProvider = "cloudflare";
    };
  };

  systemd.services = {
    immichSync = {
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        ExecStart = pkgs.writeShellScript "sync-immich" ''
          SRC="/RAID/apps/immich"
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
}
