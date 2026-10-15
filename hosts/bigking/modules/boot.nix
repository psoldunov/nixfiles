# systemd-boot, EFI vars and swraid live in modules/nixos/boot.nix.
{
  lib,
  pkgs,
  ...
}: {
  # Copy the ESP to the second NVMe after every bootloader install, so the
  # firmware can still boot from it (EFI/BOOT/BOOTX64.EFI) if nvme0 dies.
  # vfat keeps no owners or modes, and its timestamps are 2 s coarse.
  boot.loader.systemd-boot.extraInstallCommands = ''
    if ${pkgs.util-linux}/bin/mountpoint -q /boot-fallback; then
      ${pkgs.rsync}/bin/rsync -rt --modify-window=1 --delete /boot/ /boot-fallback/
    fi
  '';

  # No swap partition on the NVMe mirror.
  zramSwap.enable = true;

  # Installed fresh on this release. The baseline's 23.11 is the older
  # hosts' install release.
  system.stateVersion = lib.mkForce "26.11";
}
