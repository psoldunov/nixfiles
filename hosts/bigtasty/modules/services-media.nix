{...}: {
  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

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
