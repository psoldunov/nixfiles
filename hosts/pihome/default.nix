{
  modulesPath,
  pkgs,
  ...
}: let
  sshKeys = import ../../lib/ssh-keys.nix;
in {
  imports = [
    ./hardware.nix
    ../../modules/nixos/home-dns
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
      # /24 like every other host. The old card's /8 made the Pi treat all of
      # 10.x as on-link, so it never routed DNS replies to other VLANs.
      ipv4.addresses = [
        {
          address = "10.24.24.9";
          prefixLength = 24;
        }
      ];
    };
    wireless.enable = false;
    # DNS (53) is opened by modules/nixos/home-dns.
    firewall = {
      enable = true;
      allowedTCPPorts = [22];
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
  # AdGuard, Unbound and their secrets come from modules/nixos/home-dns.
  sops.useSystemdActivation = true;
  sops.age.keyFile = "/home/psoldunov/.config/sops/age/keys.txt";

  system.stateVersion = "26.11";
  services.journald.settings.Journal = {
    SystemMaxUse = "100M";
    RuntimeMaxUse = "32M";
    MaxRetentionSec = "14day";
  };
}
