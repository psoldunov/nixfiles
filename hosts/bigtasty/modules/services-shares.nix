{pkgs, ...}: {
  services.nfs.server = {
    enable = true;
    # Whopper is the only NFS client. The Macs use the Samba shares below.
    exports = ''
      /export/transmission 10.24.24.5(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure)
      /export/slskd 10.24.24.5(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure)
      /export/Files 10.24.24.5(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure)
      /export/Documents 10.24.24.5(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure)
      /export/Paperless 10.24.24.5(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure)
    '';
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
        "server string" = "the_server";
        "netbios name" = "BigTasty";
        "security" = "user";
        # The LAN plus WireGuard clients of the UniFi VPN server.
        "hosts allow" = "10.24.24. 192.168.77. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
        "vfs objects" = "fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
        "fruit:veto_appledouble" = "no";
        "fruit:nfs_aces" = "no";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles" = "yes";
        "fruit:posix_rename" = "yes";
      };
      "Documents" = {
        "path" = " /export/Documents";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "psoldunov";
        "force group" = "users";
      };
      "Files" = {
        "path" = " /export/Files";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "psoldunov";
        "force group" = "users";
      };
      "SLSKD" = {
        "path" = " /export/slskd";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "psoldunov";
        "force group" = "users";
      };
      "Paperless" = {
        "path" = " /export/Paperless";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "psoldunov";
        "force group" = "users";
      };
      "Transmission" = {
        "path" = " /export/transmission";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "psoldunov";
        "force group" = "users";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  services.netatalk = {
    enable = true;
    settings = {
      "transmission" = {
        path = "/export/transmission";
        "read only" = false;
      };
      "slskd" = {
        path = "/export/slskd";
        "read only" = false;
      };
      "Files" = {
        path = "/export/Files";
        "read only" = false;
      };
      "Documents" = {
        path = "/export/Documents";
        "read only" = false;
      };
    };
  };

  # Mirrors /RAID/shares to /mnt/Backup/shares. A missing source makes rsync
  # fail before it deletes anything. Staggered 5 minutes after immichSync.
  systemd.services.sharesSync = {
    description = "Mirror /RAID/shares to /mnt/Backup";
    # Requires and orders after both ends, so a restart or unmount of /RAID
    # cannot leave an empty underlying directory for rsync --delete to
    # mirror. The mountpoint check below covers the NFS side on manual runs.
    unitConfig.RequiresMountsFor = ["/RAID/shares" "/mnt/Backup"];
    path = [pkgs.rsync pkgs.util-linux];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = pkgs.writeShellScript "sync-shares" ''
        set -euo pipefail
        SRC="/RAID/shares"
        DEST="/mnt/Backup"

        if ! mountpoint -q "$DEST"; then
          echo "$DEST is not mounted, not copying" >&2
          exit 1
        fi

        rsync -a --delete "$SRC" "$DEST/"
      '';
    };
  };

  systemd.timers.sharesSync = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "10min";
      OnUnitInactiveSec = "1h";
    };
  };
}
