# AdGuard credentials from secrets/dns.yaml: the psoldunov UI login and the
# adguard CLI's login. For a host that holds the age key (BigTasty).
{
  config,
  lib,
  ...
}: {
  imports = [./.];

  homeDns.credentials = {
    configFile = config.sops.templates."adguard-config".path;
    apiFile = config.sops.templates."adguard-api.json".path;
    # A host that installs secrets from a systemd unit has to order AdGuard
    # after it; the others install them during activation.
    units = lib.optionals config.sops.useSystemdActivation ["sops-install-secrets.service"];
  };

  services.adguardhome.settings.users = [
    {
      name = "psoldunov";
      password = config.sops.placeholder.ADGUARD_ADMIN_PASSWORD_HASH;
    }
    {
      name = "adguard-cli";
      password = config.sops.placeholder.ADGUARD_CLI_PASSWORD_HASH;
    }
  ];

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
}
