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
  config,
  lib,
  pkgs,
  ...
}: let
  # Upstream has been quiet since 0.9.0, so the patches are local.
  # ./button-icon-command.patch adds `iconCommand` to the button widget: a
  # command run on the widget's interval (default 1 s) whose output names the
  # icon to show. ./action-repeat.patch adds `repeat` to an action: once the
  # key is held past the 350 ms long press, the action fires every `repeat` ms
  # until release, in place of `action_hold`.
  deckmaster = pkgs.deckmaster.overrideAttrs (old: {
    patches =
      (old.patches or [])
      ++ [
        ./button-icon-command.patch
        ./action-repeat.patch
      ];
  });

  breeze = "${pkgs.kdePackages.breeze-icons}/share/icons/breeze-dark";

  # An SVG rendered to a PNG at the MK.2 key size (72 px), since deckmaster
  # decodes raster images only.
  svgIcon = name: svg: "${pkgs.runCommand "deckmaster-${name}.png" {
      nativeBuildInputs = [pkgs.librsvg];
    } ''
      rsvg-convert --width 72 --height 72 ${svg} --output $out
    ''}";

  # A Breeze Dark icon. `path` is relative to the theme root without the
  # extension, e.g. "actions/32/media-playback-start".
  icon = path: svgIcon (baseNameOf path) "${breeze}/${path}.svg";

  # An app's own icon from the package it ships in: the scalable SVG, or the
  # 256 px PNG for apps that ship no SVG (deckmaster scales PNGs itself).
  appIcon = package: name: let
    dir = "${package}/share/icons/hicolor";
  in "${pkgs.runCommand "deckmaster-${name}.png" {
      nativeBuildInputs = [pkgs.librsvg];
    } ''
      if [ -e ${dir}/scalable/apps/${name}.svg ]; then
        rsvg-convert --width 72 --height 72 ${dir}/scalable/apps/${name}.svg --output $out
      else
        cp ${dir}/256x256/apps/${name}.png $out
      fi
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

  # An `iconCommand` that shows `playing` while any MPRIS player is playing and
  # `idle` otherwise. Plasma's media keys act on the playing player, so the
  # icon matches what a Playpause press will do.
  playerIcon = {
    playing,
    idle,
  }:
    run "player-icon" ''
      if ${lib.getExe pkgs.playerctl} --all-players status 2>/dev/null | ${pkgs.gnugrep}/bin/grep -qx Playing; then
        echo ${playing}
      else
        echo ${idle}
      fi
    '';

  # A labelled button. `hold` fires once the key is held for 350 ms. With
  # `iconCommand`, `icon` is only the first frame and the key is repainted
  # every 500 ms.
  button = index: {
    label,
    icon,
    action,
    hold ? null,
    iconCommand ? null,
  }:
    {
      inherit index action;
      widget =
        {
          id = "button";
          config =
            {
              inherit label icon;
              fontsize = 8;
            }
            // lib.optionalAttrs (iconCommand != null) {inherit iconCommand;};
        }
        // lib.optionalAttrs (iconCommand != null) {interval = 500;};
    }
    // lib.optionalAttrs (hold != null) {action_hold = hold;};

  decks = import ./decks.nix {inherit config pkgs button icon appIcon launch playerIcon;};

  toml = pkgs.formats.toml {};
  deckDir = pkgs.linkFarm "deckmaster-decks" (lib.mapAttrsToList (name: deck: {
      name = "${name}.deck";
      path = toml.generate "${name}.deck" deck;
    })
    decks);
in {
  home.packages = [deckmaster];

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
        (lib.getExe deckmaster)
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
