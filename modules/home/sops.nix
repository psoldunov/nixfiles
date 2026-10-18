# Home-level sops preamble + SHELL_SECRETS entry. Hosts override
# `defaultSopsFile` in their own home module. SHELL_SECRETS holds the
# shell-only env exports, sourced below by fish, zsh and bash.
{
  config,
  lib,
  ...
}: let
  shellSecrets = config.sops.secrets.SHELL_SECRETS.path;
  posixSource = ''
    [ -r ${shellSecrets} ] && source ${shellSecrets}
  '';
in {
  sops = {
    defaultSopsFormat = "yaml";
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

    secrets = {
      SHELL_SECRETS = {};
    };
  };

  # Before the rest of each shell's init, so everything after it sees the
  # exports.
  programs.fish.shellInitLast = lib.mkBefore ''
    if test -r ${shellSecrets}
      source ${shellSecrets}
    end
  '';
  programs.zsh.initContent = lib.mkBefore posixSource;
  programs.bash.bashrcExtra = lib.mkBefore posixSource;
}
