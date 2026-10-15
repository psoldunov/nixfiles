# The shares ADM served, with the same paths and options, so BigTasty,
# Whopper and the HTPC keep their NFS mounts as they are. The Macs use Samba.
{lib, ...}: let
  nfsOptions = "rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure";
  nfsExport = path: clients:
    path + " " + lib.concatMapStringsSep " " (client: "${client}(${nfsOptions})") clients;

  smbShare = path: {
    inherit path;
    "browseable" = "yes";
    "read only" = "no";
    "guest ok" = "no";
    "valid users" = "psoldunov";
  };

  # Nothing may be served from an empty /volume1 if the array is missing.
  needsVolume = {unitConfig.RequiresMountsFor = ["/volume1"];};
in {
  services.nfs.server = {
    enable = true;
    exports = lib.concatLines [
      (nfsExport "/volume1/Media" ["10.24.24.2" "10.24.24.5"])
      (nfsExport "/volume1/Camera" ["10.24.24.2" "10.24.24.5"])
      (nfsExport "/volume1/Backup" ["10.24.24.2" "10.24.24.5"])
      # .7 is the HTPC. It is below UniFi's DHCP pool (.10 up), so it needs a
      # static address or a UniFi Fixed IP to keep it.
      (nfsExport "/volume1/Games" ["10.24.24.2" "10.24.24.5" "10.24.24.7"])
    ];
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "netbios name" = "BigKing";
        "security" = "user";
        "hosts allow" = "10.24.24. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "map to guest" = "never";
        # ADM's Apple settings, unchanged, so the metadata and resource forks
        # its Samba stored (the Time Machine bundles included) still read.
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:encoding" = "native";
        "fruit:nfs_aces" = "no";
      };
      "Media" = smbShare "/volume1/Media";
      "Camera" = smbShare "/volume1/Camera";
      "Games" = smbShare "/volume1/Games";
      "Backup" = smbShare "/volume1/Backup";
      "Time Machine" =
        smbShare "/volume1/Time Machine"
        // {
          "fruit:time machine" = "yes";
        };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  # nixpkgs' Samba is built without mDNS, so advertise the SMB server and its
  # Time Machine share through avahi for the Macs to find.
  services.avahi = {
    enable = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
    extraServiceFiles.timemachine = ''
      <?xml version="1.0" standalone='no'?>
      <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
      <service-group>
        <name replace-wildcards="yes">%h</name>
        <service>
          <type>_smb._tcp</type>
          <port>445</port>
        </service>
        <service>
          <type>_device-info._tcp</type>
          <port>0</port>
          <txt-record>model=TimeCapsule8,119</txt-record>
        </service>
        <service>
          <type>_adisk._tcp</type>
          <txt-record>dk0=adVN=Time Machine,adVF=0x82</txt-record>
          <txt-record>sys=waMa=0,adVF=0x100</txt-record>
        </service>
      </service-group>
    '';
  };

  systemd.services.nfs-server = needsVolume;
  systemd.services.samba-smbd = needsVolume;
}
