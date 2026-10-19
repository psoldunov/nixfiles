# hardware.graphics enable/enable32Bit, services.fwupd, and the
# Apple Superdrive udev rule live in modules/nixos/hardware.nix.
{pkgs, ...}: {
  hardware.graphics = {
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
      # OpenCL for Jellyfin's HDR tone mapping. The current runtime is 12th
      # Gen and newer; legacy1 (24.35) is the last with the P630 (Gen 9.5).
      intel-compute-runtime-legacy1
      # Quick Sync runtime (libmfxhw64) for Jellyfin. vpl-gpu-rt is Gen 12+.
      intel-media-sdk
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-vaapi-driver
    ];
  };

  hardware.intel-gpu-tools.enable = true;

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
