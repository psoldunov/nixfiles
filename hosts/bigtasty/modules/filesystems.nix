{...}: {
  fileSystems."/RAID" = {
    device = "/dev/disk/by-uuid/4d2aef16-e69c-46aa-8552-3d0c1289c7f3";
    fsType = "ext4";
  };

  fileSystems."/mnt/Media" = {
    device = "10.24.24.3:/volume1/Media";
    fsType = "nfs";
    options = ["rw" "fsc" "nolock" "nconnect=16"];
  };

  fileSystems."/mnt/Backup" = {
    device = "10.24.24.3:/volume1/Backup";
    fsType = "nfs";
    options = ["rw" "fsc" "nolock"];
  };

  fileSystems."/mnt/Games" = {
    device = "10.24.24.3:/volume1/Games";
    fsType = "nfs";
    options = ["rw" "fsc" "nolock"];
  };

  fileSystems."/export/transmission" = {
    device = "/RAID/apps/transmission/downloads/complete";
    fsType = "none";
    options = ["bind"];
  };

  fileSystems."/export/slskd" = {
    device = "/RAID/apps/slskd/downloads";
    fsType = "none";
    options = ["bind"];
  };

  fileSystems."/export/Paperless" = {
    device = "/RAID/apps/paperless/consumption";
    fsType = "none";
    options = ["bind"];
  };

  fileSystems."/export/Files" = {
    device = "/RAID/shares/Files";
    fsType = "none";
    options = ["bind"];
  };

  fileSystems."/export/Documents" = {
    device = "/RAID/shares/Documents";
    fsType = "none";
    options = ["bind"];
  };
}
