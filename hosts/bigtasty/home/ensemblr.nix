# Ensemblr as a headless Environment (concierge ADR 0193): the daemon and
# CLI only, no app. Whopper's app reaches it over SSH, or over the Fleet once
# BigTasty joins one (port opened in ../modules/networking.nix). Ensemblr has
# no Sync server (ADR 0189); each Workspace lives on one Environment.
#
# The daemon's user unit outlives logins because psoldunov lingers
# (../modules/users.nix). There is no keyring here, so run
# `ensemblr secrets use-file-store` once after the first switch.
{
  inputs,
  osConfig,
  pkgs,
  ...
}: {
  imports = [inputs.concierge.homeManagerModules.ensemblr];

  programs.ensemblr = {
    enable = true;
    headless = true;
    # The range the firewall opens (../modules/networking.nix).
    portRange = {inherit (osConfig.programs.ensemblr.portRange) from to;};
    # shortcut: nixpkgs#537108's cargo hook points JEMALLOC_OVERRIDE at a
    # system jemalloc that doesn't exist; the package builds its own. Drop
    # once psoldunov/concierge's nix/ensemblr.nix sets dontCargoUseSystemLibs.
    package = inputs.concierge.packages.${pkgs.stdenv.hostPlatform.system}.ensemblr-headless.overrideAttrs {
      dontCargoUseSystemLibs = true;
    };
  };
}
