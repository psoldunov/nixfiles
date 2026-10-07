# Notion Calendar — Linux rebuild of Notion Calendar's desktop client, from
# its own flake. The flake builds against nixpkgs' Electron 43 and installs a
# `notion-calendar` binary, a desktop entry, and icons. Bump it with
# `nix flake update notion-calendar`.
#
# The package is unfree, but the flake's `packages` output allows it on its
# own, so no allowUnfree entry is needed here. The cron:// handler and the
# .ics default live in hosts/whopper/mime-defaults.nix; sign-in through the
# browser needs the handler.
{
  inputs,
  pkgs,
  ...
}: {
  home.packages = [
    inputs.notion-calendar.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
