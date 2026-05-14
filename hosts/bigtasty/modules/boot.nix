{lib, ...}: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.swraid = {
    enable = true;
    mdadmConf = ''
      MAILADDR philipp@theswisscheese.com
    '';
  };

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
