# Host-agnostic hardware baseline:
# - 64/32-bit graphics enablement (vendor-specific extraPackages stay in
#   each host's hardware.nix)
# - fwupd for firmware updates
# - Apple SuperDrive USB unlock (identical udev rule was previously
#   duplicated in both hosts)
{pkgs, ...}: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.fwupd.enable = true;

  services.udev.extraRules = ''
    ACTION=="add", ATTRS{idProduct}=="1500", ATTRS{idVendor}=="05ac", DRIVERS=="usb", RUN+="${pkgs.sg3_utils}/bin/sg_raw %r/sr%n EA 00 00 00 00 00 01"
  '';
}
