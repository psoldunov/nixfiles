{...}: {
  # Fixed names for the two RTL8125 ports (lan0 was eth0 under ADM), so the
  # bond does not depend on the names the kernel picks.
  systemd.network.links = {
    "10-lan0" = {
      matchConfig.PermanentMACAddress = "24:4b:fe:84:87:3a";
      linkConfig.Name = "lan0";
    };
    "10-lan1" = {
      matchConfig.PermanentMACAddress = "24:4b:fe:84:87:3b";
      linkConfig.Name = "lan1";
    };
  };

  networking = {
    hostName = "BigKing";
    useDHCP = false;
    defaultGateway = "10.24.24.1";
    nameservers = [
      "10.24.24.9"
    ];

    # The LACP bond ADM ran: 802.3ad, fast LACP rate, layer2+3 hashing.
    bonds.bond0 = {
      interfaces = ["lan0" "lan1"];
      driverOptions = {
        mode = "802.3ad";
        miimon = "50";
        lacp_rate = "fast";
        xmit_hash_policy = "layer2+3";
      };
    };
    interfaces.bond0.ipv4.addresses = [
      {
        address = "10.24.24.3";
        prefixLength = 24;
      }
    ];

    firewall = {
      enable = true;
      allowPing = true;
      # NFS: rpcbind, nfsd, and the statd/lockd/mountd ports pinned in
      # ./services-shares.nix. Samba, wsdd, avahi and Plex open their own.
      allowedTCPPorts = [111 2049 4000 4001 4002];
      allowedUDPPorts = [111 2049 4000 4001 4002];
    };
  };

  # openssh enable + AllowUsers live in modules/nixos/openssh.nix.
  services.openssh.settings = {
    PrintMotd = false;
    PrintLastLog = false;
  };

  # Remote rebuilds authenticate sudo with the forwarded agent, as on
  # BigTasty (the bigking entry in modules/home/workstation/ssh.nix).
  security.pam.sshAgentAuth = {
    enable = true;
    authorizedKeysFiles = ["/etc/ssh/authorized_keys.d/%u"];
  };

  security.pam.services.sudo.sshAgentAuth = true;

  security.sudo.extraConfig = ''
    Defaults env_keep += "SSH_AUTH_SOCK"
  '';
}
