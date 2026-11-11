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

  # Mirrors /RAID/apps/immich to /mnt/Backup/immich: the uploads (media plus
  # the database dumps Immich writes itself into uploads/backups, daily at
  # 2:00, last 14 kept). The live PostgreSQL data directory is not copied: a
  # file copy of a running cluster is not restorable. --delete-excluded is
  # absent on purpose, so the raw copy already on the NAS stays untouched.
  # The job fails when the NAS copy has no gzip-intact dump from the last 48
  # hours, so a stale or media-only backup shows up as a failed unit. That is
  # a freshness and integrity check only: older dumps may still restore, and
  # gzip -t does not prove the SQL restores. Verify a restore separately.
  systemd.services.immichSync = {
    description = "Mirror Immich media and database dumps to /mnt/Backup";
    # Requires and orders after both ends, so a restart or unmount of /RAID
    # cannot leave an empty underlying directory for rsync --delete to
    # mirror. The mountpoint check below covers the NFS side on manual runs.
    unitConfig.RequiresMountsFor = ["/RAID/apps/immich" "/mnt/Backup"];
    path = [pkgs.rsync pkgs.util-linux pkgs.gzip];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = pkgs.writeShellScript "sync-immich" ''
        set -euo pipefail
        SRC="/RAID/apps/immich"
        DEST="/mnt/Backup"

        if ! mountpoint -q "$DEST"; then
          echo "$DEST is not mounted, not copying" >&2
          exit 1
        fi

        rsync -a --delete \
          --exclude=/immich/postgres \
          --exclude='/immich/uploads/backups/*.tmp' \
          "$SRC" "$DEST/"

        DUMPS="$DEST/immich/uploads/backups"
        newest=$(find "$DUMPS" -maxdepth 1 -name '*.sql.gz' -size +0 -mmin -2880 \
          -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2-) || true
        if [ -z "$newest" ] || ! gzip -t "$newest"; then
          echo "no usable Immich database dump in $DUMPS: backup freshness/integrity requirement failed (need a gzip-intact .sql.gz under 48h old). Media is mirrored; verify dump restoration separately." >&2
          exit 1
        fi
        echo "newest database dump: $newest"
      '';
    };
  };

  systemd.timers.immichSync = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitInactiveSec = "1h";
    };
  };
}
