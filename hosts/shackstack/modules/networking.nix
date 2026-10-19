# Wired, static 10.24.24.7 on the I226-V. BigKing's NFS export of Games
# already names this address (hosts/bigking/modules/services-shares.nix).
#
# NetworkManager rather than scripted networking: Steam's first-time setup
# and its network settings page talk to NetworkManager, and Jovian warns
# without it. The profile is declared here, so the UI cannot drift it.
{...}: {
  networking.hostName = "ShackStack";

  networking.networkmanager = {
    enable = true;
    ensureProfiles.profiles.wired = {
      connection = {
        id = "wired";
        type = "ethernet";
        interface-name = "enp7s0";
        autoconnect = true;
      };
      # NM_SETTING_WIRED_WAKE_ON_LAN_MAGIC. Keyfiles take the flag's number;
      # the name "magic" is nmcli syntax only.
      ethernet.wake-on-lan = 64;
      ipv4 = {
        method = "manual";
        address1 = "10.24.24.7/24,10.24.24.1";
        # PiHome, then BigTasty's standby, as on the other hosts.
        dns = "10.24.24.9;10.24.24.2;";
      };
      ipv6.method = "auto";
    };
  };

  # Local caching stub in front of AdGuard Home, as on Whopper: AdGuard drops
  # a client's queries past its rate limit, and a Steam download burst would
  # otherwise stall on DNS timeouts. NetworkManager hands it the servers.
  services.resolved = {
    enable = true;
    # Avahi owns mDNS; keep resolved off UDP 5353.
    settings.Resolve.MulticastDNS = false;
  };

  # shackstack.local on the LAN.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # openssh enable + AllowUsers live in modules/nixos/openssh.nix.
  services.openssh.settings = {
    PermitRootLogin = "no";
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
  };
}
