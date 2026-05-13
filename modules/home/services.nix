{
  config,
  pkgs,
  pkgs-stable,
  ...
}: {
  systemd.user.enable = true;

  services.nextcloud-client = {
    enable = true;
    startInBackground = true;
    package = pkgs-stable.nextcloud-client;
  };

  services.gnome-keyring = {
    enable = true;
    components = ["pkcs11" "secrets"];
  };

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };

  programs = {
    btop.enable = true;
    htop.enable = true;
  };

  home.file."${config.xdg.dataHome}/nemo-python/extensions/syncstate-Nextcloud.py" = {
    source = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/psoldunov/nemo-nextcloud/master/usr/share/nemo-python/extensions/syncstate-Nextcloud.py";
      hash = "sha256-o7KnYjo6Hyz8he4gCKEPbv9hDBYXnigGf+MVHRluqeU=";
    };
  };
}
