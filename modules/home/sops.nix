# Home-level sops preamble + SHELL_SECRETS entry. Hosts override
# `defaultSopsFile` in their own home module. SHELL_SECRETS holds the
# shell-only env exports (sourced from fish/bash shellInitLast).
{config, ...}: {
  sops = {
    defaultSopsFormat = "yaml";
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

    secrets = {
      SHELL_SECRETS = {};
    };
  };
}
