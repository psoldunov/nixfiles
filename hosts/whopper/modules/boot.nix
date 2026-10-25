{
  config,
  pkgs,
  ...
}: {
  # NOTE: `amdgpu` is loaded in initrd to support early KMS + Plymouth;
  # the rest of the AMD GPU config lives in ./hardware.nix. The NFS mounts in
  # ./mounts.nix come up in stage 2, which loads `nfs` on demand, so the
  # initrd does not carry it.
  boot.initrd.kernelModules = ["amdgpu"];

  # systemd-boot, EFI vars, and swraid baseline live in modules/nixos/boot.nix.
  boot.loader.systemd-boot.consoleMode = "max";
  boot.initrd.systemd.dbus.enable = true;

  boot.supportedFilesystems = {
    hfs = true;
    hfsplus = true;
  };

  # Agent worktrees fill /tmp (31G on 2026-10-25); systemd's default keeps files 10d.
  # 00-nixos.conf sorts before systemd's tmp.conf, and per path the earliest file wins.
  systemd.tmpfiles.rules = ["q /tmp 1777 root root 3d"];
  # The upstream timer runs daily; "" clears its OnUnitActiveSec before ours applies.
  systemd.timers.systemd-tmpfiles-clean.timerConfig.OnUnitActiveSec = ["" "6h"];

  boot.plymouth = {
    enable = true;
    theme = "nixos-bgrt";
    themePackages = [pkgs.nixos-bgrt-plymouth];
    extraConfig = ''
      DeviceScale=an-integer-scaling-factor
    '';
  };

  boot = {
    consoleLogLevel = 3;
    loader.timeout = 0;
  };

  boot.loader.grub.enable = false;

  boot.kernelParams = [
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "udev.log_priority=3"
    "rd.systemd.show_status=auto"
    "amdgpu.dc=1"
    "amdgpu.dcdebugmask=0x10"
  ];

  # drivetemp publishes the SATA drives' temperatures through hwmon, where
  # lm_sensors and the Stream Deck's temperature key read them.
  boot.kernelModules = ["uinput" "uhid" "tun" "hfs" "hfsplus" "drivetemp"];

  boot.extraModulePackages = with config.boot.kernelPackages; [
    gasket
    # shortcut: DEPMOD=true keeps depmod's index files out of the package;
    # they collide with the kernel's in aggregateModules. Drop once
    # nixpkgs#575861 lands.
    (v4l2loopback.overrideAttrs (old: {
      installFlags = (old.installFlags or []) ++ ["DEPMOD=true"];
    }))
  ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';
}
