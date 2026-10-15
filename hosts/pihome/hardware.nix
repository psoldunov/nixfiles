{...}: {
  # The generic aarch64 SD-image module supplies the Raspberry Pi firmware,
  # Pi 4 device tree, U-Boot and extlinux boot layout.
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible = {
    enable = true;
    configurationLimit = 5;
  };
}
