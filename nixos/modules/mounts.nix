{...}: {
  fileSystems."/NVMe" = {
    device = "/dev/disk/by-label/NVMe";
    fsType = "ext4";
    label = "NVMe";
    options = ["defaults" "x-gvfs-show"];
  };

  fileSystems."/SATA" = {
    device = "/dev/disk/by-label/SATA";
    fsType = "ext4";
    label = "SATA";
    options = ["defaults" "x-gvfs-show"];
  };

  fileSystems."/mnt/Media" = {
    device = "10.24.24.3:/volume1/Media/";
    fsType = "nfs";
    options = ["defaults" "x-gvfs-show" "x-gvfs-symbolic-icon=media-tape-symbolic"];
  };

  fileSystems."/mnt/Files" = {
    device = "10.24.24.2:/export/Files/";
    fsType = "nfs";
    options = ["defaults" "x-gvfs-show" "x-gvfs-symbolic-icon=file-catalog-symbolic"];
  };

  fileSystems."/mnt/Documents" = {
    device = "10.24.24.2:/export/Documents/";
    fsType = "nfs";
    options = ["defaults" "x-gvfs-show" "x-gvfs-symbolic-icon=x-office-document-symbolic"];
  };

  fileSystems."/mnt/Camera" = {
    device = "10.24.24.3:/volume1/Camera/";
    fsType = "nfs";
    options = ["defaults" "x-gvfs-show" "x-gvfs-symbolic-icon=camera-symbolic"];
  };

  fileSystems."/mnt/Transmission" = {
    device = "10.24.24.2:/export/transmission";
    fsType = "nfs";
    options = ["defaults" "x-gvfs-show" "x-gvfs-symbolic-icon=folder-download-symbolic"];
  };

  fileSystems."/mnt/SLSKD" = {
    device = "10.24.24.2:/export/slskd";
    fsType = "nfs";
    options = ["defaults" "x-gvfs-show" "x-gvfs-symbolic-icon=folder-download-symbolic"];
  };

  fileSystems."/mnt/Paperless" = {
    device = "10.24.24.2:/export/paperless";
    fsType = "nfs";
    options = ["defaults" "x-gvfs-show" "x-gvfs-symbolic-icon=x-office-document-symbolic"];
  };

  fileSystems."/mnt/Games" = {
    device = "10.24.24.3:/volume1/Games";
    fsType = "nfs";
    options = ["defaults" "x-gvfs-show" "x-gvfs-symbolic-icon=folder-games-symbolic"];
  };
}
