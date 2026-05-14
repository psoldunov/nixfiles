{config, ...}: {
  services.cloudflared.tunnels."CFD_MAIN_TUNNEL".ingress = {
    "n8n.theswisscheese.com" = {
      service = "http://localhost:5678";
    };
  };

  virtualisation.oci-containers.containers = {
    n8n = {
      image = "docker.n8n.io/n8nio/n8n";
      ports = [
        "5678:5678"
      ];
      volumes = [
        "n8n_data:/home/node/.n8n"
      ];
      environment = {
        WEBHOOK_URL = "https://n8n.theswisscheese.com";
        GENERIC_TIMEZONE = "Asia/Nicosia";
        N8N_AI_ENABLED = "true";
        N8N_AI_PROVIDER = "openai";
        N8N_EMAIL_MODE = "smtp";
        N8N_SMTP_HOST = "smtp.resend.com";
        N8N_SMTP_PORT = "2465";
        N8N_SMTP_USER = "resend";
        N8N_SMTP_SENDER = "n8n@theswisscheese.com";
        N8N_SMTP_SSL = "true";
      };
      environmentFiles = [
        config.sops.secrets.N8N_SETTINGS.path
      ];
    };
  };
}
