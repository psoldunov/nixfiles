# hardware.graphics enable/enable32Bit, services.fwupd, and the
# Apple Superdrive udev rule live in modules/nixos/hardware.nix.
{pkgs, ...}: {
  hardware.graphics = {
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
      intel-compute-runtime
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-vaapi-driver
    ];
  };

  hardware.intel-gpu-tools.enable = true;

  services.cachefilesd = {
    enable = true;
    cacheDir = "/RAID/cachefilesd";
  };

  services.nbd.server = {
    enable = true;
    exports.cdrom = {
      path = "/dev/sr0";
      extraOptions = {
        readonly = true;
      };
    };
  };

  powerManagement.powertop.enable = true;

  systemd.services."mdmonitor".environment = {
    MDADM_MONITOR_ARGS = "--scan --syslog";
  };
}
