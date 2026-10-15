# Port 443 is forwarded from the WAN for Cloudflare's ranges only (UniFi
# "Reverse Proxy" port forward). Vhosts with `lanOnly` have no public DNS
# record or stay home-only on purpose; the rest are proxied by Cloudflare
# (./services-cloudflare.nix).
{config, ...}: let
  lanOnly = import ./nginx-lan-only.nix;
in {
  services.nginx = {
    enable = true;
    appendHttpConfig = ''
      proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=20g inactive=60m use_temp_path=off;
    '';
    virtualHosts = {
      # A request for the bare IP or a name no vhost serves gets its TLS
      # handshake refused (or, over HTTP, the connection dropped) instead of
      # whichever vhost nginx would pick first.
      "_" = {
        default = true;
        rejectSSL = true;
        locations."/".return = "444";
      };
      "sonarr.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig =
          ''
            client_max_body_size 500000M;
          ''
          + lanOnly;
        locations."/" = {
          proxyPass = "http://localhost:8989";
          proxyWebsockets = true;
        };
      };
      "lidarr.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig =
          ''
            client_max_body_size 500000M;
          ''
          + lanOnly;
        locations."/" = {
          proxyPass = "http://localhost:8686";
          proxyWebsockets = true;
        };
      };
      # Holds every indexer's credentials.
      "prowlarr.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = lanOnly;
        locations."/" = {
          proxyPass = "http://localhost:9696";
          proxyWebsockets = true;
        };
      };
      "radarr.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig =
          ''
            client_max_body_size 500000M;
          ''
          + lanOnly;
        locations."/" = {
          proxyPass = "http://localhost:7878";
          proxyWebsockets = true;
        };
      };
      # Portainer holds the Docker socket, i.e. root on this host.
      "portainer.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = lanOnly;
        locations."/" = {
          proxyPass = "https://localhost:9443";
          proxyWebsockets = true;
        };
      };
      "kuma.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:3001";
          proxyWebsockets = true;
        };
      };
      "jellyseerr.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = lanOnly;
        locations."/" = {
          proxyPass = "http://localhost:5055";
          proxyWebsockets = true;
        };
      };
      "homarr.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = lanOnly;
        locations."/" = {
          proxyPass = "http://localhost:7575";
          proxyWebsockets = true;
        };
      };
      # The GUI controls every synced folder.
      "syncthing.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig =
          ''
            client_max_body_size 50000M;
          ''
          + lanOnly;
        locations."/" = {
          proxyPass = "http://localhost:8384";
          proxyWebsockets = true;
        };
      };
      "jellyfin.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:8096";
        };
      };
      "immich.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = ''
          client_max_body_size 50000M;
          proxy_read_timeout 600s;
          proxy_send_timeout 600s;
          send_timeout 600s;
        '';
        locations."/" = {
          proxyPass = "http://localhost:2283";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host              $host;
            proxy_set_header X-Real-IP         $remote_addr;
            proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_redirect off;
          '';
        };
      };
      "homeassistant.theswisscheese.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:8123";
          proxyWebsockets = true;
        };
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      dnsProvider = "cloudflare";
      email = "philipp@theswisscheese.com";
      environmentFile = config.sops.secrets.CF_DNS_CREDS.path;
    };
    certs = {
      "sonarr.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "radarr.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "lidarr.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "prowlarr.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "jellyseerr.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "kuma.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "syncthing.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "homeassistant.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "jellyfin.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "immich.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "homarr.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
      "portainer.theswisscheese.com" = {
        webroot = null;
        dnsProvider = "cloudflare";
      };
    };
  };
}
