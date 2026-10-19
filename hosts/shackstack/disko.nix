# The NVMe layout nixos-anywhere creates (disko): an ESP and one btrfs
# filesystem with a subvolume each for /, /nix and /home. The whole drive is
# wiped on install; Steam re-downloads the games.
{
  disko.devices.disk.nvme = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_2TB_S69ENX0TA25215J";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            # The label is only what Dolphin and lsblk show; every mount
            # goes by partition label (disk-nvme-root).
            extraArgs = ["-f" "-L" "NixOS"];
            subvolumes = let
              # zstd:1 is what Bazzite used on this drive. Game files that
              # are already compressed cost almost nothing to try.
              mountOptions = ["compress=zstd:1" "noatime"];
            in {
              "@root" = {
                mountpoint = "/";
                inherit mountOptions;
              };
              "@nix" = {
                mountpoint = "/nix";
                inherit mountOptions;
              };
              "@home" = {
                mountpoint = "/home";
                inherit mountOptions;
              };
            };
          };
        };
      };
    };
  };
}
