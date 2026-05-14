{pkgs, ...}: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
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

  services.fwupd.enable = true;

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

  services.udev = {
    extraRules = ''
      ACTION=="add", ATTRS{idProduct}=="1500", ATTRS{idVendor}=="05ac", DRIVERS=="usb", RUN+="${pkgs.sg3_utils}/bin/sg_raw %r/sr%n EA 00 00 00 00 00 01"
    '';
  };

  powerManagement.powertop.enable = true;

  systemd.services."mdmonitor".environment = {
    MDADM_MONITOR_ARGS = "--scan --syslog";
  };
}
