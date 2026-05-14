# systemd-boot, EFI vars, and swraid baseline live in modules/nixos/boot.nix.
{lib, ...}: {
  boot.initrd.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  boot.blacklistedKernelModules = ["nouveau" "nvidia"];

  boot.kernel.sysctl = {
    "vm.overcommit_memory" = lib.mkForce 1;
  };

  environment.sessionVariables = {
    MAILADDR = "philipp@theswisscheese.com";
    LIBVA_DRIVER_NAME = "iHD";
  };
}
