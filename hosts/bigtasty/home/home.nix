{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: let
  systemStateVersion = "23.11";

  scripts = import ./scripts/default.nix {
    pkgs = pkgs;
    config = config;
  };
in {
  imports = [
    ./modules
  ];

  sops = {
    defaultSopsFile = ../../../secrets/bigtasty.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

    secrets = {
      SHELL_SECRETS = {};
    };
  };

  services.unison = {
    enable = false;
    pairs = {
      immich = {
        roots = [
          "/apps/immich"
          "/mnt/Backup/immich"
        ];
        commandOptions = {
          log = "true";
          repeat = "watch";
          auto = "true";
          batch = "true";
          ui = "text";
        };
      };
    };
  };

  programs.nix-index.enable = true;

  programs = {
    home-manager.enable = true;
    git.enable = true;
  };

  # nixpkgs.config = {
  #   allowUnfree = true;
  #   allowInsecure = true;
  # };

  home.packages = with pkgs; [
    pwgen
    scripts.convert_all_to_mkv
  ];

  home.stateVersion = systemStateVersion;
}
