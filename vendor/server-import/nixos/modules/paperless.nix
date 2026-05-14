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
      };
      environmentFiles = [
        config.sops.secrets.PAPERLESS_SETTINGS.path
      ];
      extraOptions = [
        "--network=paperless-network"
      ];
      dependsOn = ["paperless_broker" "paperless_db"];
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
