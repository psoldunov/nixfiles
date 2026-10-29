# systemd-boot, EFI vars and swraid live in modules/nixos/boot.nix. Early
# amdgpu KMS for Plymouth comes from Jovian (jovian.hardware.has.amd.gpu in
# ./game-mode.nix).
{
  lib,
  pkgs,
  ...
}: {
  # Bazzite ran a gaming-tuned kernel. The nearest match that needs no
  # local compile is the newest mainline kernel. It runs the kernel's own
  # CPU scheduler, not LAVD (see ./game-mode.nix for why).
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # An appliance boot: no menu (hold Space to get it), no text on the TV,
  # just Valve's SteamOS splash. Jovian packages the theme from SteamOS's
  # steamdeck-hw-theme; Steam's updater screen uses the same logo
  # (jovian.steam.updater.splash, "steamos" by default).
  boot.plymouth = {
    enable = true;
    theme = "steamos";
    themePackages = [pkgs.jovianPackages.steamdeck-hw-theme];
  };
  boot = {
    consoleLogLevel = 3;
    loader.timeout = 0;
  };

  boot.kernelParams = [
    "quiet"
    "splash"
    "udev.log_priority=3"
    "rd.systemd.show_status=auto"
    # Bazzite's setting for Xbox Wireless controllers over Bluetooth.
    "bluetooth.disable_ertm=1"
  ];

  # Installed fresh on this release. The baseline's 23.11 is the older
  # hosts' install release.
  system.stateVersion = lib.mkForce "26.11";
}
