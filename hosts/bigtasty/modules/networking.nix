{
  config,
  lib,
  ...
}: let
  wirelessEnabled = config.networking.wireless.enable;
in {
  networking = {
    hostName = "BigTasty";
    defaultGateway = "10.24.24.1";
    nameservers = [
      "10.24.24.9"
    ];
    wireless = {
      enable = false;
      # PSKs come from the sops-rendered secrets file below, not the store.
      secretsFile = lib.mkIf wirelessEnabled config.sops.templates."wpa_supplicant-secrets".path;
      networks = {
        "Flying Tiger Dojo" = {
          pskRaw = "ext:psk_flying_tiger_dojo";
        };
      };
    };
    interfaces = {
      eno2.useDHCP = true;
      wlo1.useDHCP = true;
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
      allowedTCPPorts = [8076 28981 9966 6432 8086 8888 8889 8766 27016 9700 3212 6443 111 2049 2222 3060 4000 4001 4002 4024 5030 9099 5031 50300 32500 4355 20048 53 80 443 2342 8123 3005 8001 9091];
      allowedUDPPorts = [53 28981 9966 8766 6432 32500 27016 9700 8086 6443 111 2222 2049 4000 4024 4001 4355 4002 20048];
    };
  };

  # wpa_supplicant resolves `ext:<name>` from `name=value` lines in
  # secretsFile. WIFI_PASSWORD holds the bare password (secrets/shared.yaml),
  # so a template adds the variable name. The service runs as the
  # `wpa_supplicant` user, which exists only while wireless is enabled, so the
  # template is gated on the same switch.
  sops.templates."wpa_supplicant-secrets" = lib.mkIf wirelessEnabled {
    owner = "wpa_supplicant";
    content = ''
      psk_flying_tiger_dojo=${config.sops.placeholder.WIFI_PASSWORD}
    '';
  };

  # openssh enable + AllowUsers live in modules/nixos/openssh.nix.
  services.openssh.settings = {
    PrintMotd = false;
    PrintLastLog = false;
  };

  security.pam.sshAgentAuth = {
    enable = true;
    authorizedKeysFiles = ["/etc/ssh/authorized_keys.d/%u"];
  };

  security.pam.services.sudo.sshAgentAuth = true;

  security.sudo.extraConfig = ''
    Defaults env_keep += "SSH_AUTH_SOCK"
  '';
}
