{config, ...}: {
  services.cloudflared.tunnels."CFD_MAIN_TUNNEL".ingress = {
    "karakeep.theswisscheese.com" = {
      service = "http://localhost:3060";
    };
  };

  services.karakeep = {
    enable = false;
    browser.enable = true;
    meilisearch.enable = true;
    environmentFile = config.sops.secrets.KARAKEEP_SETTINGS.path;
    extraEnvironment = {
      PORT = "3060";
      DISABLE_SIGNUPS = "true";
      DISABLE_NEW_RELEASE_CHECK = "true";
    };
  };
}
