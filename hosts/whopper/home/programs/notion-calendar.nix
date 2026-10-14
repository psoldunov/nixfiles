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
# Started at login in the background. A login launch (--from-login) hides the
# window only while the app's stored "open as hidden" preference is on, and
# that lives in config.json next to state the app owns, so the launcher below
# switches it on in place before starting the app. The tray icon is the menu
# bar calendar, a setting inside the app; with it off the app still starts
# hidden, just without a tray icon.
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

  # Never keeps the app from starting: a config.json it cannot parse or write
  # is left alone with a note. A missing or empty one reads as {}, as it does
  # for the app.
  launcher = pkgs.writeShellApplication {
    name = "notion-calendar-login";
    runtimeInputs = [pkgs.coreutils pkgs.jq];
    text = ''
      config="''${XDG_CONFIG_HOME:-$HOME/.config}/Notion Calendar/config.json"
      current=$(cat "$config" 2>/dev/null) || current=""
      [ -n "$current" ] || current='{}'

      if ! jq -e '.user.preferences.openAsHidden == true' <<<"$current" >/dev/null 2>&1; then
        if ! patched=$(jq '.user.preferences.openAsHidden = true' <<<"$current" 2>/dev/null); then
          echo "notion-calendar-login: left $config alone: not a JSON object" >&2
        elif ! {
          mkdir -p "$(dirname "$config")" &&
            printf '%s\n' "$patched" >"$config.tmp" &&
            mv "$config.tmp" "$config"
        }; then
          echo "notion-calendar-login: could not write $config" >&2
        fi
      fi

      exec ${lib.getExe notion-calendar} --process-start-args --from-login
    '';
  };
in {
  home.packages = [notion-calendar];

  xdg.configFile."autostart/notion-calendar.desktop" = {
    source = "${pkgs.makeDesktopItem {
      name = "notion-calendar";
      desktopName = "Notion Calendar";
      icon = "notion-calendar-desktop";
      exec = lib.getExe launcher;
      terminal = false;
    }}/share/applications/notion-calendar.desktop";
    force = true;
  };
}
