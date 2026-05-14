{config, ...}: {
  services.cloudflared.tunnels."CFD_MAIN_TUNNEL".ingress = {
    "vaultwarden.theswisscheese.com" = {
      service = "http://localhost:8222";
    };
  };

  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    domain = "vaultwarden.theswisscheese.com";
    backupDir = "/RAID/apps/vaultwarden-backup";
    environmentFile = config.sops.secrets.VAULTWARDEN_SETTINGS.path;
    config = {
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;

      SIGNUPS_ALLOWED = false;
      WEBSOCKET_ENABLED = true;

      SMTP_HOST = "smtp.resend.com";
      SMTP_PORT = 2465;
      SMTP_SECURITY = "force_tls";
      SMTP_USERNAME = "resend";
      SMTP_FROM = "vaultwarden@theswisscheese.com";
      SMTP_FROM_NAME = "Vaultwarden";
    };
  };
}
