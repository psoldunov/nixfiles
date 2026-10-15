# The household DNS server: AdGuard Home on port 53 in front of a local
# validating Unbound on 127.0.0.1:5335. PiHome is the primary and BigTasty
# the standby; both import this module, so they serve the same policy
# (./adguard-settings.nix) with the same credentials (secrets/dns.yaml).
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homeDns;
  # A host that installs secrets from a systemd unit (PiHome) has to order
  # AdGuard after it; the others install them during activation.
  sopsUnit = lib.optionals config.sops.useSystemdActivation ["sops-install-secrets.service"];
in {
  options.homeDns.uiPort = lib.mkOption {
    type = lib.types.port;
    default = 3000;
    description = "Loopback port of the AdGuard UI and API, which the adguard CLI uses.";
  };

  config = {
    networking.firewall = {
      allowedTCPPorts = [53];
      allowedUDPPorts = [53];
    };

    systemd = {
      services.adguardhome = {
        after = sopsUnit ++ ["unbound.service"];
        requires = sopsUnit;
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

    sops.secrets =
      lib.genAttrs [
        "ADGUARD_ADMIN_PASSWORD_HASH"
        "ADGUARD_CLI_PASSWORD_HASH"
        "ADGUARD_CLI_PASSWORD"
      ] (_: {
        sopsFile = ../../../secrets/dns.yaml;
        restartUnits = ["adguardhome.service"];
      });
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
      (pkgs.callPackage ../../../packages/adguard-cli {
        config = {
          mode = "local";
          base_url = "http://127.0.0.1:${toString cfg.uiPort}";
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
  };
}
