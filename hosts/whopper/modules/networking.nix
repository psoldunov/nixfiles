{inputs, ...}: {
  # Skrepka itself is installed per user through its Home Manager module
  # (home/programs/skrepka.nix). Home Manager cannot open firewall ports, so
  # the NixOS module is imported here for `openFirewall` alone, which works
  # without `enable`: TCP 27182-27183 for LAN sync and UDP 5353 for mDNS.
  #
  # Ensemblr is the same: its Home Manager module (home/programs/ensemblr.nix)
  # runs the daemon, and this NixOS module only opens ports: the Fleet's TCP
  # 7362 (Release), so the other Machines in the Fleet reach this one, and the
  # Workspaces' dev-server range, which the Home Manager side reads from here.
  imports = [
    inputs.skrepka.nixosModules.default
    inputs.concierge.nixosModules.ensemblr
  ];

  programs.skrepka.openFirewall = true;
  programs.ensemblr = {
    fleet.openFirewall = true;
    # Ensemblr's default 41000-41999 sits inside the kernel's ephemeral range
    # (32768-60999), where Steam and others bind random ports (Steam held
    # 41287). 62000-62999 is above it, clear of mosh's UDP 60000-61000, and in
    # IANA's unassigned dynamic range.
    portRange = {
      openFirewall = true;
      from = 62000;
      to = 62999;
    };
  };

  networking.hostName = "Whopper";

  # The only cabled link, enp10s0 below, is static, so DHCP is off. With it on,
  # dhcpcd waited out its 30s timeout for carrier on the idle enp8s0 and
  # wlp9s0, which held network-online.target (and with it docker and the NFS
  # mounts) back by 30s every boot. It also picked up Docker's veth pairs and
  # gave them IPv4LL addresses and a 169.254 default route.
  networking = {
    defaultGateway = "10.24.24.1";
    useDHCP = false;
    # PiHome, then BigTasty's standby; resolved moves to the next server
    # when one stops answering.
    nameservers = [
      "10.24.24.9"
      "10.24.24.2"
    ];
  };

  # Local caching stub in front of AdGuard Home (10.24.24.9). AdGuard drops a
  # client's queries past its per-client rate limit, and with no cache here
  # glibc stalled every dropped lookup for its full 5s timeout, so a page load
  # waited 5-15s on DNS. resolved answers repeats from cache, merges duplicate
  # in-flight queries and retransmits within a second. DNS= defaults to
  # networking.nameservers above.
  services.resolved = {
    enable = true;
    # Avahi owns mDNS (nssmdns4 below); keep resolved off UDP 5353.
    settings.Resolve.MulticastDNS = false;
  };

  # 10gbps card
  networking.interfaces.enp10s0 = {
    wakeOnLan.enable = true;
    ipv4.addresses = [
      {
        address = "10.24.24.5";
        prefixLength = 24;
      }
    ];
  };

  networking.firewall = {
    allowedTCPPorts = [22 59012 32500 8384 3000 3333 22000 9001 5173 5174 4567 4355 5201 53317 27040 27036 27037];
    allowedUDPPorts = [27031 32500 27032 27033 27034 27035 27036 3000 3333 22000 21027 53317 27031 27036];
    trustedInterfaces = ["virbr0"];
  };

  networking.networkmanager.enable = false;
  programs.nm-applet.enable = false;

  # openssh enable + AllowUsers live in modules/nixos/openssh.nix.
  services.openssh = {
    ports = [22];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
