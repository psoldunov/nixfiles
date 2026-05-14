{
  config,
  pkgs,
  ...
}: {
  # NOTE: `amdgpu` is loaded in initrd to support early KMS + Plymouth;
  # the rest of the AMD GPU config lives in ./hardware.nix.
  boot.initrd.kernelModules = ["amdgpu" "nfs"];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.initrd.systemd.dbus.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.supportedFilesystems = {
    hfs = true;
    hfsplus = true;
  };

  boot.plymouth = {
    enable = true;
    theme = "pedro-raccoon";
    themePackages = [pkgs.pedro-raccoon-plymouth];
    extraConfig = ''
      DeviceScale=an-integer-scaling-factor
    '';
  };

  boot = {
    consoleLogLevel = 3;
    initrd.verbose = false;
    loader.timeout = 0;
  };

  boot.loader.grub.enable = false;

  boot.kernelParams = [
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "udev.log_priority=3"
    "rd.systemd.show_status=auto"
    "video=DP-1:3840x2160@144"
    "amdgpu.dc=1"
    "amdgpu.dcdebugmask=0x10"
  ];

  boot.kernelModules = ["uinput" "uhid" "tun" "hfs" "hfsplus"];

  boot.extraModulePackages = with config.boot.kernelPackages; [
    gasket
    v4l2loopback
  ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';

  boot.swraid.enable = true;
  boot.swraid.mdadmConf = "MAILADDR=philipp@theswisscheese.com";
}
