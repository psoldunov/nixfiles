# Notion Calendar — Linux rebuild of Notion Calendar's desktop client, from
# its own flake. The flake builds against nixpkgs' Electron 43 and installs a
# `notion-calendar` binary, a desktop entry, and icons. Bump it with
# `nix flake update notion-calendar`.
#
# The package is unfree, but the flake's `packages` output allows it on its
# own, so no allowUnfree entry is needed here. The cron:// handler and the
# .ics default live in hosts/whopper/mime-defaults.nix; sign-in through the
# browser needs the handler.
#
# Started at login in the background: --start-hidden starts it in the tray.
#
# The autostart file name is the one the app's own "Open at login" writes.
# Leave that setting on: switching it off deletes this entry until the next
# rebuild. The app also tries to rewrite the entry on every start, which
# fails on the read-only link and only logs an error.
{
  inputs,
  lib,
  pkgs,
  ...
}: let
  notion-calendar = inputs.notion-calendar.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  home.packages = [notion-calendar];

  xdg.configFile."autostart/notion-calendar.desktop" = {
    source = "${pkgs.makeDesktopItem {
      name = "notion-calendar";
      desktopName = "Notion Calendar";
      icon = "notion-calendar-desktop";
      exec = "${lib.getExe notion-calendar} --process-start-args --from-login --start-hidden";
      terminal = false;
    }}/share/applications/notion-calendar.desktop";
    force = true;
  };
}
