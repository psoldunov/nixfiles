{config, ...}: {
  systemd.user.enable = true;

  # Must track the same nixpkgs as the system graphics stack: a stable-channel
  # build links an older Qt/Mesa and cannot create a GL context against the
  # unstable Mesa in /run/opengl-driver, which aborts every Qt Quick window.
  services.nextcloud-client = {
    enable = true;
    startInBackground = true;
  };

  # The service module only runs the client; it does not put the package in the
  # profile. Installing it exposes the Dolphin sync-state overlay and context
  # menu plugins (lib/qt-6/plugins/kf6) on QT_PLUGIN_PATH, replacing the old
  # Nemo extension.
  home.packages = [config.services.nextcloud-client.package];

  # Secrets are handled by KWallet, unlocked at login by pam_kwallet from the
  # plasma6 module. Running gnome-keyring alongside it made both daemons race
  # for the org.freedesktop.secrets bus name.

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
}
