{
  config,
  pkgs,
  ...
}: {
  # Declare the Spotifyd password secret. Separate from the global sops
  # block so this module stays self-contained.
  sops.secrets.SPOTIFYD_PASSWORD = {};

  services.spotifyd = {
    enable = true;
    settings = {
      global = {
        username = "philipp@theswisscheese.com";
        # NOTE: the previous cleartext password value is still in git
        # history. Rotate it in the Spotify account settings after
        # activation.
        password_cmd = "cat ${config.sops.secrets.SPOTIFYD_PASSWORD.path}";
        use_keyring = true;
        use_mpris = true;
        dbus_type = "session";
        backend = "pulseaudio";
        audio_format = "F32";
        device_name = "Whopper";
        bitrate = 320;
        cache_path = "${config.xdg.cacheHome}/spotifyd";
        max_cache_size = 1000000000;
        initial_volume = "90";
        volume_normalisation = false;
        autoplay = true;
        zeroconf_port = 1234;
        device_type = "computer";
      };
    };
  };
}
