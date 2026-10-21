{
  config,
  lib,
  ...
}: let
  policy = import ./adguard-settings.nix;
in
  lib.recursiveUpdate policy {
    # `users` comes from ./sops.nix or ./boot-credentials.nix.
    http = {address = "127.0.0.1:${toString config.homeDns.uiPort}";};
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
