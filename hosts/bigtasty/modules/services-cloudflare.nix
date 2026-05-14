{config, ...}: {
  services.cloudflared = {
    enable = true;
    tunnels = {
      "CFD_MAIN_TUNNEL" = {
        credentialsFile = config.sops.secrets.CFD_MAIN_TUNNEL.path;
        default = "http_status:404";
        ingress = {
          "search.theswisscheese.com" = {
            service = "http://localhost:9080";
          };
        };
      };
    };
  };

  services.cloudflare-dyndns = {
    enable = true;
    proxied = true;
    apiTokenFile = config.sops.secrets.CFDYNDNS_TOKEN.path;
    domains = [
      "kuma.theswisscheese.com"
      "syncthing.theswisscheese.com"
      "jellyfin.theswisscheese.com"
      "immich.theswisscheese.com"
      "homeassistant.theswisscheese.com"
      "prowlarr.theswisscheese.com"
      "sotf.theswisscheese.com"
      "portainer.theswisscheese.com"
    ];
  };
}
