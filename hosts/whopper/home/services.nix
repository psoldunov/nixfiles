{
  config,
  pkgs,
  ...
}: {
  systemd.user.enable = true;

  # Must track the same nixpkgs as the system graphics stack: a stable-channel
  # build links an older Qt/Mesa and cannot create a GL context against the
  # unstable Mesa in /run/opengl-driver, which aborts every Qt Quick window.
  services.nextcloud-client = {
    enable = true;
    startInBackground = true;
  };

  services.gnome-keyring = {
    enable = true;
    components = ["pkcs11" "secrets"];
  };

  # programs.nix-index lives in modules/home/nix-index.nix.
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
