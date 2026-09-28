# Deckmaster — drives the Elgato Stream Deck MK.2 from decks declared in Nix.
#
# ./decks.nix holds the layout: one attribute per page, each written in
# deckmaster's own TOML schema (https://github.com/muesli/deckmaster#configuration),
# so its README maps one-to-one onto the Nix. Every page is rendered into a
# single store directory, which keeps page switches (`action.deck =
# "system.deck"`) relative, and the unit points at that directory, so a layout
# change is a new unit and home-manager restarts the daemon on switch.
#
# The system side lives in hosts/whopper/modules/hardware.nix: a udev rule
# grants the seat user the device, links it as /dev/streamdeck and starts this
# unit on hotplug. The user sits in the `uinput` group for key emulation.
#
# On unplug the daemon exits with an error and the restart is skipped by the
# ExecCondition, so the unit goes quiet instead of failing in a loop.
{
  lib,
  pkgs,
  ...
}: let
  breeze = "${pkgs.kdePackages.breeze-icons}/share/icons/breeze-dark";

  # A Breeze Dark icon rendered to a PNG at the MK.2 key size (72 px), since
  # deckmaster decodes raster images only. `path` is relative to the theme root
  # without the extension, e.g. "actions/32/media-playback-start".
  icon = path: "${pkgs.runCommand "deckmaster-${baseNameOf path}.png" {
      nativeBuildInputs = [pkgs.librsvg];
    } ''
      rsvg-convert --width 72 --height 72 ${breeze}/${path}.svg --output $out
    ''}";

  # deckmaster splits `exec` on spaces and runs it without a shell, so every
  # command becomes a script whose store path has none.
  run = name: script: "${pkgs.writeShellScript "deckmaster-${name}" script}";

  # Launches an app by its desktop file ID through KIO, as the Plasma launcher
  # does. The app gets its own systemd scope, so it outlives a daemon restart.
  launch = desktopId:
    run "launch-${desktopId}" ''
      exec ${pkgs.kdePackages.kde-cli-tools}/bin/kstart --application ${desktopId}
    '';

  # A labelled button. `hold` fires once the key is held for 350 ms.
  button = index: {
    label,
    icon,
    action,
    hold ? null,
  }:
    {
      inherit index action;
      widget = {
        id = "button";
        config = {
          inherit label icon;
          fontsize = 8;
        };
      };
    }
    // lib.optionalAttrs (hold != null) {action_hold = hold;};

  decks = import ./decks.nix {inherit button icon launch;};

  toml = pkgs.formats.toml {};
  deckDir = pkgs.linkFarm "deckmaster-decks" (lib.mapAttrsToList (name: deck: {
      name = "${name}.deck";
      path = toml.generate "${name}.deck" deck;
    })
    decks);
in {
  home.packages = [pkgs.deckmaster];

  systemd.user.services.deckmaster = {
    Unit = {
      Description = "Deckmaster Stream Deck daemon";
      Documentation = "https://github.com/muesli/deckmaster";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };

    Service = {
      ExecCondition = "${pkgs.coreutils}/bin/test -e /dev/streamdeck";
      ExecStart = lib.concatStringsSep " " [
        (lib.getExe pkgs.deckmaster)
        "-deck ${deckDir}/main.deck"
        "-brightness 70"
        "-sleep 30m"
      ];
      # SIGHUP makes deckmaster re-read the current deck file.
      ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install.WantedBy = ["graphical-session.target"];
  };
}
