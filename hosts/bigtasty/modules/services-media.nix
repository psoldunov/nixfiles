{lib, ...}: {
  # nixpkgs' Jellyfin module writes MPEG-2 into encoding.xml as "mpeg2", but
  # Jellyfin matches the ffprobe name "mpeg2video". The module writes every
  # enabled attr name, so add that one. Drop this once nixpkgs fixes it: an
  # upstream mpeg2video option would fail the build as a duplicate.
  imports = [
    {
      options.services.jellyfin.transcoding.hardwareDecodingCodecs = lib.mkOption {
        type = lib.types.submodule {
          options.mpeg2video = lib.mkEnableOption "hardware decoding for mpeg2video codec";
        };
      };
    }
  ];

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
    # Quick Sync on the UHD P630 (Coffee Lake, Gen 9.5), which can't decode
    # AV1 or HEVC RExt, or encode AV1. Low-power encoding stays off: on Gen 9
    # it needs GuC/HuC firmware, which isn't set up.
    hardwareAcceleration = {
      enable = true;
      type = "qsv";
      device = "/dev/dri/renderD128";
    };
    transcoding = {
      enableHardwareEncoding = true;
      enableToneMapping = true;
      hardwareDecodingCodecs = {
        h264 = true;
        hevc = true;
        hevc10bit = true;
        vp9 = true;
        vp8 = true;
        # Not mpeg2: see the import at the top.
        mpeg2video = true;
        vc1 = true;
      };
      hardwareEncodingCodecs.hevc = true;
    };
    # Nix owns encoding.xml: dashboard transcoding changes are reset on
    # restart. The module keeps the old file as encoding.xml.backup-<timestamp>.
    forceEncodingConfig = true;
  };

  services.uptime-kuma = {
    enable = true;
    settings = {
      PORT = "3001";
    };
  };

  programs.chromium.enable = true;
}
