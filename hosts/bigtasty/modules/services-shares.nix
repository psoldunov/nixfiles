{pkgs, ...}: {
  services.nfs.server = {
    enable = true;
    exports = ''
      /export/transmission 10.24.24.5(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure) 10.24.24.6(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure) 10.24.24.88(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure)
      /export/slskd 10.24.24.5(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure) 10.24.24.6(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure) 10.24.24.88(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure)
      /export/Files 10.24.24.5(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure) 10.24.24.6(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure) 10.24.24.88(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure)
      /export/Documents 10.24.24.5(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure)
      /export/Paperless 10.24.24.5(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure) 10.24.24.6(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure) 10.24.24.88(rw,async,no_root_squash,anonuid=0,anongid=0,subtree_check,no_wdelay,secure)
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
        "hosts allow" = "10.24.24. 127.0.0.1 localhost";
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

  systemd.services.sharesSync = {
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      ExecStart = pkgs.writeShellScript "shares-immich" ''
        SRC="/RAID/shares"
        DEST="/mnt/Backup"

        while ${pkgs.inotify-tools}/bin/inotifywait -r -e modify,create,delete,move $SRC; do
            ${pkgs.rsync}/bin/rsync -av --delete $SRC $DEST
        done
      '';
      User = "root";
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };
}
