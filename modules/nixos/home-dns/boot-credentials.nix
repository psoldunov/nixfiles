# AdGuard credentials for a host that must not hold the age key (PiHome:
# anyone can pull its SD card and read it). Every boot makes a new random
# password for the adguard CLI. Its bcrypt hash goes into AdGuard's config
# and the password into a root-only file; both live on tmpfs under /run.
# There is no separate UI login: in an emergency, tunnel to the UI over SSH
# and sign in as adguard-cli with the password from
# `sudo cat /run/adguard-credentials/adguard-api.json`.
{
  config,
  pkgs,
  ...
}: let
  dir = "/run/adguard-credentials";
  hashPlaceholder = "@ADGUARD_CLI_PASSWORD_HASH@";
  template = pkgs.writeText "adguard-config.json" (builtins.toJSON config.services.adguardhome.settings);
in {
  imports = [./.];

  homeDns.credentials = {
    configFile = "${dir}/adguard-config";
    apiFile = "${dir}/adguard-api.json";
    units = ["adguard-credentials.service"];
  };

  services.adguardhome.settings.users = [
    {
      name = "adguard-cli";
      password = hashPlaceholder;
    }
  ];

  # adguardhome Requires= this unit, so restarting it (a policy change edits
  # the template) restarts AdGuard onto the new password too.
  systemd.services.adguard-credentials = {
    description = "Random AdGuard password for the adguard CLI";
    path = [pkgs.mkpasswd];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "adguard-credentials";
      RuntimeDirectoryMode = "0700";
      UMask = "0077";
    };
    script = ''
      password=$(head -c 24 /dev/urandom | base64 -w0 | tr -d '+/=')
      hash=$(printf %s "$password" | mkpasswd --method=bcrypt --stdin)
      sed "s|${hashPlaceholder}|$hash|" ${template} > ${dir}/adguard-config
      printf '{"username": "adguard-cli", "password": "%s"}\n' "$password" > ${dir}/adguard-api.json
    '';
  };
}
