{config, ...}: {
  # Each service module adds its own hostname to this tunnel's ingress.
  services.cloudflared = {
    enable = true;
    tunnels = {
      "CFD_MAIN_TUNNEL" = {
        credentialsFile = config.sops.secrets.CFD_MAIN_TUNNEL.path;
        default = "http_status:404";
      };
    };
  };

  # Proxied A records for the WAN IP, which forwards 443 to nginx from
  # Cloudflare's ranges only. Syncthing, Prowlarr and Portainer were dropped
  # from this list and are LAN-only (./services-web.nix). SotF was dropped too:
  # its server is UDP-only, which the proxy cannot carry, and nginx has no
  # vhost for it. Removing a name here does not delete its record in
  # Cloudflare.
  services.cloudflare-dyndns = {
    enable = true;
    proxied = true;
    apiTokenFile = config.sops.secrets.CFDYNDNS_TOKEN.path;
    domains = [
      "kuma.theswisscheese.com"
      "jellyfin.theswisscheese.com"
      "immich.theswisscheese.com"
      "homeassistant.theswisscheese.com"
      "cal.theswisscheese.com"
    ];
  };
}
