# Nightly audio cleanup of the media library, for the LG C2 (no DTS
# decoder): DTS becomes AC3 and audio that is not English, Russian or the
# title's original language goes. The script's docstring has the details.
# Only files that need a change are rewritten, so a night that runs out
# of time carries on from where it stopped the next night.
#
# Manual run, e.g. one file now or a preview of the whole library:
#   media-audio-fix --sonarr-config ... --radarr-config ... <file.mkv>
#   systemctl start media-audio-fix  (logs: journalctl -u media-audio-fix)
{
  config,
  lib,
  pkgs,
  ...
}: let
  mediaAudioFix =
    pkgs.writers.writePython3Bin "media-audio-fix" {
      flakeIgnore = ["E501" "W503"];
    }
    (builtins.readFile ./media-audio-fix.py);
in {
  environment.systemPackages = [mediaAudioFix];

  systemd.services.media-audio-fix = {
    description = "Replace DTS with AC3 and drop unwanted audio languages in /mnt/Media";
    after = ["network-online.target" "sonarr.service" "radarr.service"];
    wants = ["network-online.target"];
    unitConfig.RequiresMountsFor = ["/mnt/Media"];
    # jellyfin-ffmpeg is the build Jellyfin itself runs.
    path = [pkgs.jellyfin-ffmpeg];
    serviceConfig = {
      Type = "oneshot";
      # Owns the library, and can read the *arr config.xml for API keys.
      User = "psoldunov";
      Group = "users";
      ExecStart = lib.concatStringsSep " " [
        (lib.getExe mediaAudioFix)
        "--deadline 07:30"
        "--sonarr-config ${config.services.sonarr.dataDir}/config.xml"
        "--radarr-config ${config.services.radarr.dataDir}/config.xml"
      ];
      Nice = 19;
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "batch";
    };
  };

  systemd.timers.media-audio-fix = {
    wantedBy = ["timers.target"];
    timerConfig.OnCalendar = "*-*-* 01:00:00";
  };
}
