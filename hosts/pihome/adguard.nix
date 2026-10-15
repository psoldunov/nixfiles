{
  config,
  lib,
  ...
}: let
  policy = import ./adguard-settings.nix;
in
  lib.recursiveUpdate policy {
    http = {address = "127.0.0.1:3000";};
    users = [
      {
        name = "psoldunov";
        password = config.sops.placeholder.ADGUARD_ADMIN_PASSWORD_HASH;
      }
      {
        name = "adguard-cli";
        password = config.sops.placeholder.ADGUARD_CLI_PASSWORD_HASH;
      }
    ];
    dns = {
      bind_hosts = ["0.0.0.0"];
      upstream_dns = ["127.0.0.1:5335"];
      upstream_dns_file = "";
      bootstrap_dns = [];
      fallback_dns = [];
      upstream_mode = "load_balance";
    };
    filtering = {
      protection_enabled = true;
      protection_disabled_until = null;
    };
  }
