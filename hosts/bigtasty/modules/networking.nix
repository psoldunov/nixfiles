{...}: {
  networking = {
    hostName = "BigTasty";
    defaultGateway = "10.24.24.1";
    nameservers = [
      "10.24.24.9"
    ];
    wireless = {
      enable = false;
      networks = {
        "Flying Tiger Dojo" = {
          psk = "U2qsWznpDKzUAk";
        };
      };
    };
    interfaces = {
      eno2.useDHCP = true;
      wl01.useDHCP = true;
      enp8s0.ipv4.addresses = [
        {
          address = "10.24.24.2";
          prefixLength = 24;
        }
      ];
    };

    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [8076 28981 9966 6432 8086 8888 8889 8766 27016 9700 3212 6443 111 2049 2222 3060 4000 4001 4002 4024 5030 9099 5031 50300 32500 4355 20048 53 80 443 2342 8123 11434 3005 8001 9091];
      allowedUDPPorts = [53 28981 9966 8766 6432 32500 27016 9700 8086 6443 111 2222 2049 11434 4000 4024 4001 4355 4002 20048];
    };
  };

  services.openssh = {
    enable = true;
    settings.AllowUsers = ["psoldunov"];
  };

  security.sudo.extraRules = [
    {
      users = ["psoldunov"];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = ["NOPASSWD" "SETENV"];
        }
        {
          command = "/run/current-system/sw/bin/switch-to-configuration";
          options = ["NOPASSWD" "SETENV"];
        }
      ];
    }
  ];
}
