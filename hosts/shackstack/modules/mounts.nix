# BigKing's Games share, which already exports to 10.24.24.7
# (hosts/bigking/modules/services-shares.nix). It mounts on first access
# rather than at boot, so a sleeping NAS never holds up Gaming Mode.
{...}: {
  fileSystems."/mnt/Games" = {
    device = "10.24.24.3:/volume1/Games";
    fsType = "nfs";
    options = [
      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=10"
      "_netdev"
      "nofail"
    ];
  };
}
