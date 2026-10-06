{
  config,
  pkgs,
  pkgs-stable,
  ...
}: {
  services.cloudflared.tunnels."CFD_MAIN_TUNNEL".ingress = {
    "paperless.theswisscheese.com" = {
      service = "http://localhost:28981";
    };
  };

  virtualisation.oci-containers.containers = {
    paperless_webserver = {
      image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
      volumes = [
        "paperless_data:/usr/src/paperless/data"
        "/RAID/apps/paperless/media:/usr/src/paperless/media"
        "/RAID/apps/paperless/export:/usr/src/paperless/export"
        "/RAID/apps/paperless/consumption:/usr/src/paperless/consume"
      ];
      ports = ["28981:8000"];
      environment = {
        PAPERLESS_REDIS = "redis://paperless-broker:6379";
        PAPERLESS_DBHOST = "paperless-db";
        PAPERLESS_URL = "https://paperless.theswisscheese.com";
        PAPERLESS_ADMIN_USER = "psoldunov";
        PAPERLESS_OCR_LANGUAGE = "eng+ell+rus";
        PAPERLESS_OCR_LANGUAGES = "eng est ell rus";
        # Office documents (.doc/.docx/.xlsx, ...) are parsed by Tika and
        # converted to PDF by Gotenberg; without them they fail to consume.
        PAPERLESS_TIKA_ENABLED = "1";
        PAPERLESS_TIKA_ENDPOINT = "http://paperless-tika:9998";
        PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://paperless-gotenberg:3000";
      };
      environmentFiles = [
        config.sops.secrets.PAPERLESS_SETTINGS.path
      ];
      extraOptions = [
        "--network=paperless-network"
      ];
      dependsOn = ["paperless_broker" "paperless_db" "paperless_gotenberg" "paperless_tika"];
      autoStart = true;
    };
    paperless_gotenberg = {
      image = "docker.io/gotenberg/gotenberg:8.37";
      hostname = "paperless-gotenberg";
      # The Chromium route converts .eml files; keep it from loading remote
      # content such as tracking pixels or running JavaScript.
      cmd = [
        "gotenberg"
        "--chromium-disable-javascript=true"
        "--chromium-allow-list=file:///tmp/.*"
      ];
      extraOptions = [
        "--network=paperless-network"
      ];
      autoStart = true;
    };
    paperless_tika = {
      image = "docker.io/apache/tika:3.3.1.0";
      hostname = "paperless-tika";
      extraOptions = [
        "--network=paperless-network"
      ];
      autoStart = true;
    };
    paperless_broker = {
      image = "docker.io/library/redis:8";
      hostname = "paperless-broker";
      volumes = [
        "paperless_redisdata:/data"
      ];
      extraOptions = [
        "--network=paperless-network"
      ];
      autoStart = true;
    };
    paperless_db = {
      image = "docker.io/library/postgres:17";
      volumes = [
        "paperless_pgdata:/var/lib/postgresql/data"
      ];
      environment = {
        POSTGRES_USER = "paperless";
        POSTGRES_DB = "paperless";
        POSTGRES_PASSWORD = "paperless";
      };
      hostname = "paperless-db";
      extraOptions = [
        "--network=paperless-network"
      ];
      autoStart = true;
    };
  };
}
