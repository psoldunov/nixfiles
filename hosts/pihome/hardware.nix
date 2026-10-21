{lib, ...}: {
  # The generic aarch64 SD-image module supplies the Raspberry Pi firmware,
  # Pi 4 device tree, U-Boot and extlinux boot layout.
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible = {
    enable = true;
    configurationLimit = 5;
  };

  # The SD image also turns on every redistributable firmware blob, about
  # 900 MB. Ethernet and USB on the Pi 4 need none of it; only the Wi-Fi
  # chip asks for a file, and Wi-Fi is off.
  hardware.enableRedistributableFirmware = lib.mkForce false;
}
