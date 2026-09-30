{inputs, ...}: {
  # Skrepka itself is installed per user through its Home Manager module
  # (home/programs/skrepka.nix). Home Manager cannot open firewall ports, so
  # the NixOS module is imported here for `openFirewall` alone, which works
  # without `enable`: TCP 27182-27183 for LAN sync and UDP 5353 for mDNS.
  imports = [inputs.skrepka.nixosModules.default];

  programs.skrepka.openFirewall = true;

  networking.hostName = "Whopper";

  networking = {
    defaultGateway = "10.24.24.1";
    useDHCP = true;
    nameservers = [
      "10.24.24.9"
    ];
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

  # Sunshine's ports (TCP 47984, 47989, 47990, 48010; UDP 47998-48000, 48002,
  # 48010) come from services.sunshine.openFirewall in ./sunshine.
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
