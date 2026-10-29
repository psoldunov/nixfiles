# SearXNG for agents. Claude Code, Codex and pi search through the searxng MCP
# server (modules/home/programs/claude-code/mcp.nix); scripts can call the JSON
# API at $SEARXNG_URL/search?q=...&format=json. SearXNG listens on loopback
# only, nginx in front of it adds Basic Auth, and CFD_MAIN_TUNNEL exposes
# nginx. The tunnel's public hostnames are dashboard routes, so
# search.theswisscheese.com -> http://127.0.0.1:8791 lives there as well.
{config, ...}: {
  services.cloudflared.tunnels."CFD_MAIN_TUNNEL".ingress = {
    "search.theswisscheese.com".service = "http://127.0.0.1:8791";
  };

  services.searx = {
    enable = true;
    # SEARXNG_SECRET=...: SearXNG refuses to start on the stock secret_key.
    environmentFile = config.sops.secrets.SEARXNG_ENV.path;
    settings = {
      general.instance_name = "The Search Cheese";
      server = {
        bind_address = "127.0.0.1";
        port = 8790;
        base_url = "https://search.theswisscheese.com/";
        secret_key = "$SEARXNG_SECRET";
      };
      # Agents read json; SearXNG answers it with 403 unless it is listed.
      search.formats = ["html" "json"];
      # Brave rate-limits this IP ("too many requests") on most queries.
      # Entries merge into the stock engine list by name.
      engines =
        map (name: {
          inherit name;
          disabled = true;
        }) ["brave" "brave.images" "brave.news" "brave.videos"];
    };
  };

  services.nginx.virtualHosts."search.theswisscheese.com" = {
    # Plain HTTP on loopback: only cloudflared connects, and TLS ends at Cloudflare.
    listen = [
      {
        addr = "127.0.0.1";
        port = 8791;
      }
    ];
    basicAuthFile = config.sops.secrets.SEARXNG_HTPASSWD.path;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8790";
      recommendedProxySettings = true;
    };
  };
}
