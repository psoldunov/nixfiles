# hardware.graphics enable and fwupd live in modules/nixos/hardware.nix.
{pkgs, ...}: {
  # UHD Graphics 600: VA-API for Plex hardware transcoding.
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
  ];

  # Warn when a disk passes 45 °C, in case the fan control (./asustor) is
  # not keeping up. Short self-test daily at 02:00, long one Saturdays at 03:00.
  services.smartd = {
    enable = true;
    defaults.monitored = "-a -o on -s (S/../.././02|L/../../6/03) -W 4,45,50";
  };

  environment.systemPackages = with pkgs; [
    lm_sensors
  ];

  # No mail transport here; log array events instead.
  systemd.services."mdmonitor".environment = {
    MDADM_MONITOR_ARGS = "--scan --syslog";
  };
}
