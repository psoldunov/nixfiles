{...}: {
  sops = {
    defaultSopsFile = ../../../secrets/bigtasty.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/psoldunov/.config/sops/age/keys.txt";

    secrets = {
      SLSKD_ENV = {
        group = "docker";
      };
      JELLYPLEX_ENV = {
        group = "docker";
      };
      CFDYNDNS_TOKEN = {
        owner = "psoldunov";
      };
      CFDYNDNS_API_KEY = {
        owner = "psoldunov";
      };
      CF_DNS_CREDS = {
        group = "acme";
      };
      OPENAI_API_KEY = {
        group = "docker";
      };
      CFD_MAIN_TUNNEL = {
        owner = "cloudflared";
      };
      N8N_SETTINGS = {
        owner = "psoldunov";
      };
      PAPERLESS_SETTINGS = {
        group = "docker";
      };
      HOMARR_SETTINGS = {
        group = "docker";
      };
      IMMICH_SETTINGS = {};
      KARAKEEP_SETTINGS = {};
      NOCODB_SETTINGS = {
        group = "docker";
      };
      TRANSMISSION = {
        group = "docker";
      };
      CLAWDBOT_TELEGRAM_BOT_TOKEN = {
        owner = "psoldunov";
      };
      VAULTWARDEN_SETTINGS = {
        owner = "vaultwarden";
      };
      INFISICAL_SETTINGS = {
        group = "docker";
      };
    };
  };
}
