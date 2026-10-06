{...}: {
  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  # Cloudflare challenges RuTracker's login.php for non-browser clients, so
  # Prowlarr routes that indexer through FlareSolverr (indexer proxy at
  # http://localhost:8191/, matched by tag). Local only: firewall stays closed.
  services.flaresolverr.enable = true;

  services.radarr = {
    enable = true;
    openFirewall = true;
    user = "psoldunov";
    group = "users";
  };

  services.lidarr = {
    enable = true;
    openFirewall = true;
    user = "psoldunov";
    group = "users";
  };

  services.sonarr = {
    enable = true;
    openFirewall = true;
    user = "psoldunov";
    group = "users";
  };

  services.seerr = {
    enable = true;
    openFirewall = true;
  };

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  services.uptime-kuma = {
    enable = true;
    settings = {
      PORT = "3001";
    };
  };

  programs.chromium.enable = true;
}
