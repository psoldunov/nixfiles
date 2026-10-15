# DNS servers the dashboard probes, at the LAN addresses clients use, and
# the checks run against each (blackbox modules in ./default.nix).
{
  servers = [
    {
      host = "PiHome";
      role = "primary";
      target = "10.24.24.9:53";
    }
    {
      host = "BigTasty";
      role = "standby";
      target = "10.24.24.2:53";
    }
  ];
  checks = [
    {
      name = "public name";
      module = "dns_resolves";
    }
    {
      # A public answer here would mean AdGuard's policy is not loaded.
      name = "local rewrite";
      module = "dns_rewrite";
    }
  ];
}
