# Hardware of ShackStack: ASUS ROG STRIX B760-I GAMING WIFI, i5-12600K (its
# iGPU is off in the firmware), 32 GB, Radeon RX 7800 XT, Samsung 980 PRO
# behind Intel VMD. Written from the probe of the running Bazzite install,
# not by nixos-generate-config. The file systems come from ./disko.nix.
{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # The NVMe sits behind Intel VMD (the firmware's RAID mode), so the initrd
  # needs `vmd` before it can see the disk. Same list as Whopper's board.
  boot.initrd.availableKernelModules = ["vmd" "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod"];
  boot.kernelModules = ["kvm-intel"];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;
}
