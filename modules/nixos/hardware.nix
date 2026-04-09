{
  inputs,
  pkgs,
  ...
}: let
  pkgs-hyprland = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  # NOTE: `boot.initrd.kernelModules = ["amdgpu" ...]` is set in ./boot.nix
  # because it is a boot-time concern, even though the GPU is configured here.
  hardware.graphics = {
    enable = true;
    package = pkgs-hyprland.mesa;
    enable32Bit = true;
    package32 = pkgs-hyprland.pkgsi686Linux.mesa;
    extraPackages = with pkgs; [
      libva
      libva-vdpau-driver
      vdpauinfo
      libvdpau
      libvpx
      libvdpau-va-gl
      libGL
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.libva-vdpau-driver
      driversi686Linux.vdpauinfo
      driversi686Linux.libvdpau-va-gl
    ];
  };

  hardware.amdgpu.opencl.enable = true;

  hardware.keyboard.zsa.enable = true;
  hardware.keyboard.qmk.enable = true;

  hardware = {
    openrazer = {
      enable = true;
      users = ["psoldunov"];
      batteryNotifier.enable = true;
    };
    logitech = {
      wireless = {
        enable = true;
        enableGraphical = true;
      };
    };
    sane.enable = true;
    bluetooth = {
      enable = true;
    };
    uinput.enable = true;
    xone.enable = true;
    i2c.enable = true;
  };

  hardware.printers = {
    ensurePrinters = [
      {
        name = "HP_LaserJet_MFP_M28w_9B18D8";
        location = "Office";
        deviceUri = "http://10.24.24.229:631";
        model = "drv:///hp/hpcups.drv/hp-laserjet_pro_mfp_m27cnw.ppd";
        ppdOptions = {
          PageSize = "A4";
        };
      }
    ];
    ensureDefaultPrinter = "HP_LaserJet_MFP_M28w_9B18D8";
  };
}
