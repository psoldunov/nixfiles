# systemd-boot, EFI vars, and swraid baseline live in modules/nixos/boot.nix.
{lib, ...}: {
  boot.initrd.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  boot.blacklistedKernelModules = ["nouveau" "nvidia"];

  boot.kernel.sysctl = {
    "vm.overcommit_memory" = lib.mkForce 1;
    # BigTasty froze on 2026-11-11 with nothing in the journal and stayed down
    # until a power cycle. A detected lockup now panics, and a panic reboots
    # after 10s instead of hanging forever.
    "kernel.softlockup_panic" = 1;
    "kernel.hardlockup_panic" = 1;
    "kernel.panic" = 10;
  };

  # PID 1 pets the hardware watchdog (/dev/watchdog0, intel_oc_wdt); if it
  # stops for 60s the board resets. Covers freezes the kernel doesn't detect.
  systemd.settings.Manager.RuntimeWatchdogSec = "60s";

  environment.sessionVariables = {
    MAILADDR = "philipp@theswisscheese.com";
    LIBVA_DRIVER_NAME = "iHD";
  };
}
