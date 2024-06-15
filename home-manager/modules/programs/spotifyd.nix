{
  config,
  libs,
  pkgs,
  ...
}: {
  services.spotifyd = {
    enable = true;
    settings = {
      global = {
        username = "philipp@theswisscheese.com";
        password = "jpn-qpx!ZTB-nea7adk";
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
