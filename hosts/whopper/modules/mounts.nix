{...}: let
  # Local ext4 volumes skip access-time updates. The default, relatime, still
  # writes an inode the first time a file is read each day.
  localOptions = ["defaults" "noatime" "x-gvfs-show"];

  # nconnect spreads each NFS server's traffic over 8 TCP connections instead
  # of one, so throughput over the 10GbE link (enp10s0) is not capped by a
  # single connection. The kernel shares one client per server, so every
  # mount from the same server must carry the same value.
  nfsOptions = ["defaults" "nconnect=8" "x-gvfs-show"];

  # Each share carries two icon hints. Dolphin's places panel reads fstab
  # through KDE Solid, which honours `x-gvfs-icon` and ignores
  # `x-gvfs-symbolic-icon` (without either it falls back to network-server).
  # GTK apps reading fstab through gvfs use the symbolic one.
  nfsShare = {
    device,
    icon,
    symbolicIcon,
  }: {
    inherit device;
    fsType = "nfs";
    options =
      nfsOptions
      ++ [
        "x-gvfs-icon=${icon}"
        "x-gvfs-symbolic-icon=${symbolicIcon}"
      ];
  };
in {
  # / comes from ../hardware.nix (generated); this adds to its option list.
  fileSystems."/".options = ["noatime"];

  fileSystems."/NVMe" = {
    device = "/dev/disk/by-label/NVMe";
    fsType = "ext4";
    label = "NVMe";
    options = localOptions;
  };

  fileSystems."/SATA" = {
    device = "/dev/disk/by-label/SATA";
    fsType = "ext4";
    label = "SATA";
    options = localOptions;
  };

  # Compressed swap in RAM, used before the swap partition in ../hardware.nix
  # (zram's priority 5 outranks the partition's -2). Pages pushed out under
  # memory pressure, such as during a big nix build, stay in RAM at roughly a
  # third of their size instead of going to the NVMe.
  zramSwap.enable = true;

  fileSystems."/mnt/Media" = nfsShare {
    device = "10.24.24.3:/volume1/Media";
    icon = "folder-videos";
    symbolicIcon = "media-tape-symbolic";
  };

  fileSystems."/mnt/Files" = nfsShare {
    device = "10.24.24.2:/export/Files";
    icon = "folder-remote";
    symbolicIcon = "file-catalog-symbolic";
  };

  fileSystems."/mnt/Documents" = nfsShare {
    device = "10.24.24.2:/export/Documents";
    icon = "folder-documents";
    symbolicIcon = "x-office-document-symbolic";
  };

  fileSystems."/mnt/Camera" = nfsShare {
    device = "10.24.24.3:/volume1/Camera";
    icon = "folder-pictures";
    symbolicIcon = "camera-symbolic";
  };

  fileSystems."/mnt/Transmission" = nfsShare {
    device = "10.24.24.2:/export/transmission";
    icon = "folder-download";
    symbolicIcon = "folder-download-symbolic";
  };

  fileSystems."/mnt/SLSKD" = nfsShare {
    device = "10.24.24.2:/export/slskd";
    icon = "folder-download";
    symbolicIcon = "folder-download-symbolic";
  };

  fileSystems."/mnt/Paperless" = nfsShare {
    device = "10.24.24.2:/export/Paperless";
    icon = "folder-documents";
    symbolicIcon = "x-office-document-symbolic";
  };

  fileSystems."/mnt/Games" = nfsShare {
    device = "10.24.24.3:/volume1/Games";
    icon = "folder-games";
    symbolicIcon = "folder-games-symbolic";
  };
}
