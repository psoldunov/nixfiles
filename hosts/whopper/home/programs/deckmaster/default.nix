# Whopper's Stream Deck MK.2: the pages in ./decks.nix, run as a systemd user
# service by the shared deckmaster module in modules/home/programs/deckmaster,
# whose lib.nix holds the key helpers both hosts use. What is here is
# Plasma's: app launches through KIO, MPRIS and PipeWire state on the keys,
# Breeze app icons and the pomodoro timer's notification settings.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  deck = import ../../../../../modules/home/programs/deckmaster/lib.nix {inherit lib pkgs inputs;};
  inherit (deck) run;

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

  # An `iconCommand` that shows `muted` while the default output is muted and
  # `unmuted` otherwise. Plasma's mute key acts on the default output, so the
  # icon shows the state a Mute press toggles.
  muteIcon = {
    muted,
    unmuted,
  }:
    run "mute-icon" ''
      if [[ $(${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null) == *MUTED* ]]; then
        echo ${muted}
      else
        echo ${unmuted}
      fi
    '';

  # A key running a pomodoro timer, and the Plasma settings it needs.
  pomodoro = import ./pomodoro.nix {
    inherit lib pkgs;
    inherit (deck) button icon;
  };

  # A key for the Clokkr time tracker from ../clokkr.nix.
  clokkrKey = deck.clokkrKey {
    clokkr = config.programs.clokkr.package;
    placeholder = appIcon config.programs.clokkr.package "dev.soldunov.clokkr";
  };
in {
  imports = [../../../../../modules/home/programs/deckmaster];

  programs.deckmaster.decks = import ./decks.nix {
    inherit config pkgs deck appIcon launch playerIcon muteIcon clokkrKey;
    pomodoroKey = pomodoro.key;
  };

  programs.plasma.configFile.plasmanotifyrc = pomodoro.notifyrc;
}
