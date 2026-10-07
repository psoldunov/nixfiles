# A Stream Deck pomodoro timer. ./pomodoro.sh keeps the timer and draws its
# key: the phase, the time left over a ring that empties as the phase runs
# down, and a dot for each focus session finished in the round. A tap starts,
# pauses or resumes the phase; holding the key stops it, and holding it again
# clears the finished sessions. Every phase end posts a notification and plays
# a sound, whichever page the deck shows and even while it sleeps. A running
# focus phase turns on Plasma's Do Not Disturb, and the timer's own popups show
# through it.
#
# Evaluates to `key`, the key at an index, and `notifyrc`, the plasmanotifyrc
# settings that let the popups through, for programs.plasma.configFile.
{
  lib,
  pkgs,
  button,
  icon,
}: let
  # The notifications go out under this name, Plasma's x-kde-appname hint,
  # which keys their settings in plasmanotifyrc's [Services] group.
  service = "deckmaster-pomodoro";

  pomodoro = lib.getExe (pkgs.writeShellApplication {
    name = "deckmaster-pomodoro";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.kdePackages.kconfig
      pkgs.libnotify
      pkgs.librsvg
      pkgs.pipewire
      pkgs.systemd
      pkgs.util-linux
    ];
    runtimeEnv = {
      FOCUS_MINUTES = 40;
      BREAK_MINUTES = 7;
      LONG_BREAK_MINUTES = 30;
      # Focus sessions in a round. The last one is followed by the long break.
      SESSIONS = 4;
      SOUNDS = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo";
      NOTIFY_SERVICE = service;
    };
    text = builtins.readFile ./pomodoro.sh;
  });
in {
  # The key at `index`. It has no label, so the drawing fills the key; the
  # placeholder icon shows only until the first drawing.
  key = index:
    button index {
      label = "";
      icon = icon "actions/22/chronometer";
      iconCommand = "${pomodoro} icon";
      action.exec = "${pomodoro} toggle";
      hold.exec = "${pomodoro} stop";
    };

  # System Settings' "Show in Do Not Disturb mode" for the timer, so the popup
  # ending a focus phase shows even if Do Not Disturb has not lifted yet, and
  # "Break over" stays up once the next focus phase turns it on.
  notifyrc."Services/${service}".ShowPopupsInDndMode = true;
}
