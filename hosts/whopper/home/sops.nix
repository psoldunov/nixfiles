{config, ...}: {
  sops = {
    defaultSopsFile = ../../../secrets/whopper.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

    secrets = {
      SHELL_SECRETS = {};
    };
  };
}
