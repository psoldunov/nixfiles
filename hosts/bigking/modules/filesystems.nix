# ADM's data volume, kept as it was: an mdadm RAID 0 across partition 4 of
# the four WD Reds (array name AS6604T-873A:1), formatted btrfs. ADM keeps
# everything in the `base` subvolume and mounts it at /volume1; doing the
# same keeps the paths the other hosts mount (10.24.24.3:/volume1/...).
{...}: {
  fileSystems."/volume1" = {
    device = "/dev/disk/by-uuid/8e580e43-364b-421a-9efa-63b00b1a16d2";
    fsType = "btrfs";
    # nofail: if the array does not assemble, the box still boots and stays
    # reachable over SSH instead of waiting in an emergency shell. The
    # services that need the volume require the mount (RequiresMountsFor).
    options = ["subvol=base" "nofail"];
  };
}
