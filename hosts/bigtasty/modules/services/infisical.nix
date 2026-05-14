{config, ...}: {
  services.cloudflared.tunnels."CFD_MAIN_TUNNEL".ingress = {
    "infisical.theswisscheese.com" = {
      service = "http://localhost:8088";
    };
  };

  virtualisation.oci-containers.containers = {
    infisical = {
      image = "infisical/infisical:latest";
      ports = ["8088:8080"];
      environment = {
        SITE_URL = "https://infisical.theswisscheese.com";
        TELEMETRY_ENABLED = "false";
        SMTP_HOST = "smtp.resend.com";
        SMTP_PORT = "587";
        SMTP_USERNAME = "resend";
        SMTP_FROM_ADDRESS = "infisical@theswisscheese.com";
        SMTP_FROM_NAME = "Infisical";
      };
      environmentFiles = [
        config.sops.secrets.INFISICAL_SETTINGS.path
      ];
      extraOptions = [
        "--network=infisical-network"
      ];
      dependsOn = ["infisical_db" "infisical_redis"];
    };
    infisical_db = {
      image = "postgres:16.6";
      hostname = "infisical_db";
      volumes = [
        "infisical_pgdata:/var/lib/postgresql/data"
      ];
      environment = {
        POSTGRES_DB = "infisical";
        POSTGRES_USER = "infisical";
      };
      environmentFiles = [
        config.sops.secrets.INFISICAL_SETTINGS.path
      ];
      extraOptions = [
        "--network=infisical-network"
        "--health-cmd=pg_isready -U \"$$POSTGRES_USER\" -d \"$$POSTGRES_DB\""
        "--health-interval=10s"
        "--health-timeout=2s"
        "--health-retries=10"
      ];
    };
    infisical_redis = {
      image = "redis:7-alpine";
      hostname = "infisical_redis";
      volumes = [
        "infisical_redis:/data"
      ];
      extraOptions = [
        "--network=infisical-network"
      ];
    };
  };
}
