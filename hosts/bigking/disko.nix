# The NVMe layout nixos-anywhere creates (disko). Both drives are the
# Crucial P5s that used to be ADM's SSD cache: an ESP on each, the rest of
# each one a member of an mdadm RAID1 holding /.
#
# The four WD Reds are deliberately absent. disko only touches the disks
# listed here, and the data array on them is mounted as it is in
# ./modules/filesystems.nix.
let
  nvme = serial: espMountpoint: {
    type = "disk";
    device = "/dev/disk/by-id/nvme-CT1000P5PSSD8_${serial}";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = espMountpoint;
            mountOptions = ["umask=0077"];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "mdraid";
            name = "root";
          };
        };
      };
    };
  };
in {
  disko.devices = {
    disk = {
      nvme0 = nvme "22343ABE1CCC" "/boot";
      # Kept in step with /boot by ./modules/boot.nix.
      nvme1 = nvme "22343ABF8F10" "/boot-fallback";
    };

    mdadm.root = {
      type = "mdadm";
      level = 1;
      content = {
        type = "filesystem";
        format = "ext4";
        mountpoint = "/";
      };
    };
  };

  # A dead second drive must not stop the boot.
  fileSystems."/boot-fallback".options = ["nofail"];
}
