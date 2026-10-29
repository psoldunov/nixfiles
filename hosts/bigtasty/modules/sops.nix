# defaultSopsFormat + age.keyFile live in modules/nixos/sops.nix.
{...}: {
  sops = {
    defaultSopsFile = ../../../secrets/bigtasty.yaml;

    secrets = {
      SLSKD_ENV = {
        group = "docker";
      };
      CFDYNDNS_TOKEN = {
        owner = "psoldunov";
      };
      CF_DNS_CREDS = {
        group = "acme";
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
      NOCODB_SETTINGS = {
        group = "docker";
      };
      VAULTWARDEN_SETTINGS = {
        owner = "vaultwarden";
      };
      INFISICAL_SETTINGS = {
        group = "docker";
      };
      CAL_DIY_SETTINGS = {
        group = "docker";
        # The path stays the same when the contents change, so the container
        # would keep the old environment until something else restarted it.
        restartUnits = ["docker-cal-diy.service"];
      };
      # Resend API key; concierge-server reads it via LoadCredential, as root.
      CONCIERGE_SMTP_PASSWORD = {};
      # SEARXNG_SECRET=..., SearXNG's secret_key (./services/searxng.nix).
      SEARXNG_ENV = {};
      # psoldunov:<apr1 hash>, the Basic Auth login in front of SearXNG. Its
      # password is the one inside SEARXNG_URL in shared.yaml. Not bcrypt:
      # nixpkgs' nginx has no libcrypt, so crypt() hashes answer 500.
      SEARXNG_HTPASSWD = {
        owner = "nginx";
      };
      SYNCTHING_GUI_PASSWORD = {
        owner = "psoldunov";
        sopsFile = ../../../secrets/shared.yaml;
      };
      # WiFi PSK, rendered into wpa_supplicant's secrets file (./networking.nix).
      WIFI_PASSWORD = {
        sopsFile = ../../../secrets/shared.yaml;
      };
    };
  };
}
