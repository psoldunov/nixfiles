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

  # Server and ML track the same major version, as upstream's example.env
  # does (IMMICH_VERSION=v3). The floating `release` tag jumps majors on its
  # own, which is how v3 dropping pgvecto.rs took Immich down unnoticed.
  virtualisation.oci-containers.containers = {
    immich_server = {
      image = "ghcr.io/immich-app/immich-server:v3";
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
      image = "ghcr.io/immich-app/immich-machine-learning:v3-openvino";
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
    # Upstream replaced Redis with Valkey. It only holds the job queues and has
    # no volume, so nothing carries over between containers anyway.
    immich_redis = {
      image = "docker.io/valkey/valkey:9@sha256:70739f85ad2ee01a726a965584a0f94895f01b0c60b3cc8b0aeef11eaa6888cf";
      autoStart = true;
      extraOptions = [
        "--health-cmd=redis-cli ping | grep -q PONG || exit 1"
        "--net-alias=redis"
        "--net-alias=immich_redis"
        "--network=immich-network"
      ];
    };
    # Immich v3 dropped pgvecto.rs. This upstream image ships both VectorChord
    # and pgvecto.rs, so the server can migrate the old `vectors` indexes on
    # startup. Its entrypoint renders postgresql.conf (shared_preload_libraries
    # included), so don't override `cmd`.
    immich_postgres = {
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
      environment = {
        POSTGRES_INITDB_ARGS = "--data-checksums";
      };
      environmentFiles = [
        config.sops.secrets.IMMICH_SETTINGS.path
      ];
      hostname = "postgres";
      extraOptions = [
        "--shm-size=128m"
        "--network=immich-network"
        "--net-alias=database"
        "--net-alias=immich_postgres"
        "--net-alias=immich-postgres"
      ];
      volumes = [
        "/RAID/apps/immich/postgres:/var/lib/postgresql/data"
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
