# Launch URLs are user-facing; probes bypass public DNS/tunnels and test local origins.
let
  web = name: port: unit: {
    inherit name unit;
    url = "https://${name}.theswisscheese.com";
    target = "http://127.0.0.1:${toString port}/";
    module = "http_reachable";
    note = "Origin reachability, not authenticated application correctness";
  };
in [
  (web "sonarr" 8989 "sonarr")
  (web "radarr" 7878 "radarr")
  (web "lidarr" 8686 "lidarr")
  (web "prowlarr" 9696 "prowlarr")
  (web "jellyseerr" 5055 "seerr")
  (web "jellyfin" 8096 "jellyfin")
  (web "kuma" 3001 "uptime-kuma")
  (web "syncthing" 8384 "syncthing")
  (web "immich" 2283 "docker-immich_server")
  (web "homeassistant" 8123 "docker-homeassistant")
  (
    (web "portainer" 9443 "docker-portainer-ce")
    // {
      target = "https://127.0.0.1:9443/";
      module = "portainer_reachable";
      note = "Only this loopback self-signed origin skips TLS certificate verification";
    }
  )
  (web "homarr" 7575 "docker-homarr")
  (web "paperless" 28981 "docker-paperless_webserver")
  (web "nocodb" 8080 "docker-nocodb")
  (web "n8n" 5678 "docker-n8n")
  (web "infisical" 8088 "docker-infisical")
  (web "vaultwarden" 8222 "vaultwarden")
  (web "cal" 3010 "docker-cal-diy")
  (
    (web "plex" 32400 "plex")
    // {
      url = "http://10.24.24.2:32400/web";
      target = "http://127.0.0.1:32400/web/";
    }
  )
  ((web "transmission" 9091 "docker-transmission") // {url = "http://10.24.24.2:9091";})
  (
    (web "slskd" 5030 "docker-slskd")
    // {
      url = "http://10.24.24.2:5030";
      note = "Configured link only: port mapping 5030 conflicts with ASPNETCORE_HTTP_PORTS=7080; probe may fail until separately fixed";
    }
  )
]
