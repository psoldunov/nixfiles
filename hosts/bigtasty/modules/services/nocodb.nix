{config, ...}: {
  services.cloudflared.tunnels."CFD_MAIN_TUNNEL".ingress = {
    "nocodb.theswisscheese.com" = {
      service = "http://localhost:8080";
    };
  };

  virtualisation.oci-containers.containers = {
    nocodb = {
      image = "nocodb/nocodb:latest";
      ports = ["8080:8080"];
      volumes = [
        "nocodb_data:/usr/app/data"
      ];
      environment = {
        NC_SMTP_FROM = "nocodb@theswisscheese.com";
        NC_SMTP_FROM_DOMAIN = "theswisscheese.com";
        NC_PUBLIC_URL = "https://nocodb.theswisscheese.com";
        NC_SMTP_HOST = "smtp.resend.com";
        NC_SMTP_PORT = "465";
        NC_SMTP_USERNAME = "resend";
        NC_INVITE_ONLY_SIGNUP = "true";
      };
      environmentFiles = [
        config.sops.secrets.NOCODB_SETTINGS.path
      ];
      extraOptions = [
        "--network=nocodb-network"
      ];
      dependsOn = ["nocodb_db"];
    };
    nocodb_db = {
      image = "postgres:16.6";
      hostname = "root_db";
      volumes = [
        "nocodb_pgdata:/var/lib/postgresql/data"
      ];
      environment = {
        POSTGRES_DB = "root_db";
        POSTGRES_USER = "postgres";
      };
      environmentFiles = [
        config.sops.secrets.NOCODB_SETTINGS.path
      ];
      extraOptions = [
        "--network=nocodb-network"
        "--health-cmd=pg_isready -U \"$$POSTGRES_USER\" -d \"$$POSTGRES_DB\""
        "--health-interval=10s"
        "--health-timeout=2s"
        "--health-retries=10"
      ];
    };
  };
}
