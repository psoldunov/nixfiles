# BigKing's Games share, which already exports to 10.24.24.7
# (hosts/bigking/modules/services-shares.nix). It mounts on first access
# rather than at boot, so a sleeping NAS never holds up Gaming Mode.
#
# x-gvfs-show lists it in Dolphin's places panel, as on Whopper
# (hosts/whopper/modules/mounts.nix explains the two icon hints); opening it
# there triggers the automount.
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
      "x-gvfs-show"
      "x-gvfs-icon=folder-games"
      "x-gvfs-symbolic-icon=folder-games-symbolic"
    ];
  };
}
