{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}: let
  sshKeys = import ../../lib/ssh-keys.nix;
  adguardConfig = import ./adguard.nix {inherit config lib pkgs;};
in {
  imports = [
    ./hardware.nix
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
  ];

  networking = {
    hostName = "pi-home";
    defaultGateway = "10.24.24.1";
    nameservers = ["127.0.0.1"];
    useDHCP = false;
    usePredictableInterfaceNames = false;
    interfaces.eth0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "10.24.24.9";
          prefixLength = 8;
        }
      ];
    };
    wireless.enable = false;
    firewall = {
      enable = true;
      allowedTCPPorts = [22 53];
      allowedUDPPorts = [53];
    };
  };

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Asia/Nicosia";
  # DNSSEC needs correct time before the local resolver can resolve NTP names.
  services.timesyncd = {
    servers = ["162.159.200.1" "162.159.200.123"];
    fallbackServers = [];
  };

  users.users.psoldunov = {
    isNormalUser = true;
    uid = 1000;
    description = "Philipp Soldunov";
    shell = pkgs.fish;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys =
      sshKeys.authorized
      ++ [
        sshKeys.identities.id_ed25519
        sshKeys.identities."sudo-pihome"
      ];
  };
  programs.fish.enable = true;

  # A dedicated forwarded-agent identity authorizes Pi sudo; ordinary login
  # keys remain able to SSH in but cannot escalate through PAM.
  environment.etc."ssh/sudo_authorized_keys" = {
    text = sshKeys.sudo.pihome + "\n";
    mode = "0444";
  };

  services.openssh = {
    enable = true;
    settings = {
      AllowUsers = ["psoldunov"];
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      PrintMotd = false;
    };
  };
  security.pam.sshAgentAuth = {
    enable = true;
    authorizedKeysFiles = ["/etc/ssh/sudo_authorized_keys"];
  };
  security.pam.services.sudo.sshAgentAuth = true;
  security.sudo.extraConfig = ''
    Defaults env_keep += "SSH_AUTH_SOCK"
    Defaults:psoldunov noninteractive_auth
  '';

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    warn-dirty = false;
    auto-optimise-store = true;
    trusted-users = ["root" "psoldunov"];
    max-jobs = 1;
    cores = 2;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  systemd = {
    services.adguardhome = {
      after = ["sops-install-secrets.service" "unbound.service"];
      requires = ["sops-install-secrets.service"];
      wants = ["unbound.service"];
      serviceConfig.LoadCredential = "adguard-config:${config.sops.templates."adguard-config".path}";
      preStart = lib.mkForce ''
        install -m 600 "$CREDENTIALS_DIRECTORY/adguard-config" "$STATE_DIRECTORY/AdGuardHome.yaml"
        ${lib.getExe config.services.adguardhome.package} -c "$STATE_DIRECTORY/AdGuardHome.yaml" --check-config
      '';
    };
    services.unbound.serviceConfig = {
      RuntimeDirectory = "unbound";
      RuntimeDirectoryMode = "0750";
    };
  };

  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    settings = adguardConfig;
  };

  services.unbound = {
    enable = true;
    resolveLocalQueries = false;
    enableRootTrustAnchor = true;
    localControlSocketPath = "/run/unbound/unbound.ctl";
    settings.server = {
      interface = ["127.0.0.1@5335"];
      port = 5335;
      do-ip4 = true;
      do-ip6 = false;
      access-control = ["127.0.0.0/8 allow"];
      hide-identity = true;
      hide-version = true;
      qname-minimisation = true;
      harden-dnssec-stripped = true;
      val-permissive-mode = false;
    };
  };

  sops.useSystemdActivation = true;
  sops.defaultSopsFile = ../../secrets/pihome.yaml;
  sops.age.keyFile = "/home/psoldunov/.config/sops/age/keys.txt";
  sops.secrets = {
    ADGUARD_ADMIN_PASSWORD_HASH.restartUnits = ["adguardhome.service"];
    ADGUARD_CLI_PASSWORD_HASH.restartUnits = ["adguardhome.service"];
    ADGUARD_CLI_PASSWORD.restartUnits = ["adguardhome.service"];
  };
  sops.templates = {
    "adguard-config" = {
      mode = "0400";
      content = builtins.toJSON config.services.adguardhome.settings;
      restartUnits = ["adguardhome.service"];
    };
    "adguard-api.json" = {
      mode = "0400";
      content = builtins.toJSON {
        username = "adguard-cli";
        password = config.sops.placeholder.ADGUARD_CLI_PASSWORD;
      };
    };
  };

  environment.systemPackages = [
    pkgs.dig
    (pkgs.callPackage ../../packages/adguard-cli {
      config = {
        mode = "local";
        base_url = "http://127.0.0.1:3000";
        credentials_file = config.sops.templates."adguard-api.json".path;
        unbound_control = [
          "${pkgs.unbound}/bin/unbound-control"
          "-c"
          (pkgs.writeText "unbound-control.conf" ''
            remote-control:
              control-enable: yes
              control-interface: /run/unbound/unbound.ctl
              control-use-cert: no
          '')
          "flush_zone"
          "."
        ];
      };
    })
  ];

  system.stateVersion = "26.11";
  services.journald.settings.Journal = {
    SystemMaxUse = "100M";
    RuntimeMaxUse = "32M";
    MaxRetentionSec = "14day";
  };
}
