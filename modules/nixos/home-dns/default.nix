# The household DNS server: AdGuard Home on port 53 in front of a local
# validating Unbound on 127.0.0.1:5335. PiHome is the primary and BigTasty
# the standby; both serve the same policy (./adguard-settings.nix). Hosts
# import one of the two credential flavours, which imports this file:
# ./sops.nix (BigTasty, secrets/dns.yaml) or ./boot-credentials.nix
# (PiHome, which holds no age key).
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homeDns;
in {
  options.homeDns = {
    uiPort = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Loopback port of the AdGuard UI and API, which the adguard CLI uses.";
    };
    credentials = {
      configFile = lib.mkOption {
        type = lib.types.str;
        description = "Root-only AdGuardHome.yaml with the users' password hashes filled in.";
      };
      apiFile = lib.mkOption {
        type = lib.types.str;
        description = "Root-only JSON with the username and password the adguard CLI logs in with.";
      };
      units = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "systemd units that must write both files before AdGuard starts.";
      };
    };
  };

  config = {
    networking.firewall = {
      allowedTCPPorts = [53];
      allowedUDPPorts = [53];
    };

    # The workstation adguard CLI runs `sudo -n` over SSH. Without this,
    # sudo -n gives up before pam_ssh_agent_auth can accept the forwarded key.
    security.sudo.extraConfig = ''
      Defaults:psoldunov noninteractive_auth
    '';

    systemd = {
      services.adguardhome = {
        after = cfg.credentials.units ++ ["unbound.service"];
        requires = cfg.credentials.units;
        wants = ["unbound.service"];
        serviceConfig.LoadCredential = "adguard-config:${cfg.credentials.configFile}";
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
      settings = import ./adguard.nix {inherit config lib;};
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

    environment.systemPackages = [
      pkgs.dig
      (pkgs.callPackage ../../../packages/adguard-cli {
        config = {
          mode = "local";
          base_url = "http://127.0.0.1:${toString cfg.uiPort}";
          credentials_file = cfg.credentials.apiFile;
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
  };
}
