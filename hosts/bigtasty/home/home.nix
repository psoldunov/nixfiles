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
    ../../../modules/home
  ];

  # Preamble + SHELL_SECRETS live in modules/home/sops.nix.
  sops.defaultSopsFile = ../../../secrets/bigtasty.yaml;

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

  # programs.nix-index lives in modules/home/nix-index.nix.
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
