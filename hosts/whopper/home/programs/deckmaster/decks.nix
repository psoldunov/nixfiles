# Stream Deck pages. Each attribute becomes <name>.deck; deckmaster opens
# `main` first. Keys are numbered 0-14, left to right and top to bottom:
#
#    0  1  2  3  4
#    5  6  7  8  9
#   10 11 12 13 14
#
# Widgets and actions follow https://github.com/muesli/deckmaster#configuration.
# `keycode` presses go through a virtual keyboard on /dev/uinput, so Plasma
# handles them like the real keys: media and volume keys drive MPRIS and the
# volume OSD, and chords reach the shortcuts in ../../desktop/plasma-shortcuts.nix
# (Meta+Shift+4 for a Spectacle region capture, Meta+L to lock). A keycode that
# has no name in deckmaster's table can be given as its number, as with 248
# (KEY_MICMUTE) below.
{
  config,
  pkgs,
  button,
  icon,
  appIcon,
  launch,
  playerIcon,
}: let
  back = index:
    button index {
      label = "Back";
      icon = icon "actions/32/go-previous";
      action.deck = "main.deck";
    };

  # The bottom row of every page that plays music.
  mediaKeys = [
    (button 10 {
      label = "Previous";
      icon = icon "actions/32/media-skip-backward";
      action.keycode = "Previoussong";
    })
    (button 11 {
      label = "Play/Pause";
      icon = icon "actions/32/media-playback-start";
      # Shows pause while something plays, play otherwise.
      iconCommand = playerIcon {
        playing = icon "actions/32/media-playback-pause";
        idle = icon "actions/32/media-playback-start";
      };
      action.keycode = "Playpause";
    })
    (button 12 {
      label = "Next";
      icon = icon "actions/32/media-skip-forward";
      action.keycode = "Nextsong";
    })
    (button 13 {
      label = "Vol -";
      icon = icon "status/24/audio-volume-low";
      action.keycode = "Volumedown";
      hold.keycode = "Mute";
    })
    (button 14 {
      label = "Vol +";
      icon = icon "status/24/audio-volume-high";
      action.keycode = "Volumeup";
      hold.keycode = "Mute";
    })
  ];
in {
  main.keys =
    [
      {
        index = 0;
        widget = {
          id = "time";
          config = {
            format = "%H;%i;%s";
            font = "bold;regular;thin";
          };
        };
      }
      {
        index = 1;
        widget = {
          id = "time";
          config = {
            format = "%D;%d;%M";
            font = "regular;bold;regular";
          };
        };
      }
      {
        index = 2;
        widget = {
          id = "top";
          config = {
            mode = "cpu";
            fillColor = "#3daee9";
          };
        };
      }
      {
        index = 3;
        widget = {
          id = "top";
          config = {
            mode = "memory";
            fillColor = "#27ae60";
          };
        };
      }
      # wttr.in, located by IP address. Set `location` to pin a city.
      {
        index = 4;
        widget = {
          id = "weather";
          config.unit = "celsius";
        };
      }

      (button 5 {
        label = "Terminal";
        icon = appIcon config.programs.kitty.package "kitty";
        action.exec = launch "kitty";
      })
      (button 6 {
        label = "Browser";
        icon = icon "apps/48/internet-web-browser";
        action.exec = launch "zen";
      })
      (button 7 {
        label = "Files";
        icon = icon "apps/64/system-file-manager";
        action.exec = launch "org.kde.dolphin";
      })
      (button 8 {
        label = "Music";
        icon = icon "places/64/folder-music";
        action.deck = "music.deck";
      })
      (button 9 {
        label = "System";
        icon = icon "apps/48/preferences-system";
        action.deck = "system.deck";
      })
    ]
    ++ mediaKeys;

  # Icons come from the installed packages the launchers start: ../../packages.nix
  # (Cider, Plexamp, Shortwave), ../../../modules/packages.nix (Rhythmbox) and
  # the plasma6 module (Elisa).
  music.keys =
    [
      (back 0)
      (button 1 {
        label = "Cider";
        icon = appIcon pkgs.cider-2 "cider-2";
        action.exec = launch "cider-2";
      })
      (button 2 {
        label = "Plexamp";
        icon = appIcon pkgs.plexamp "plexamp";
        action.exec = launch "plexamp";
      })
      (button 3 {
        label = "Shortwave";
        icon = appIcon pkgs.shortwave "de.haeckerfelix.Shortwave";
        action.exec = launch "de.haeckerfelix.Shortwave";
      })
      (button 4 {
        label = "Elisa";
        icon = appIcon pkgs.kdePackages.elisa "elisa";
        action.exec = launch "org.kde.elisa";
      })
      (button 5 {
        label = "Rhythmbox";
        icon = appIcon pkgs.rhythmbox "org.gnome.Rhythmbox3";
        action.exec = launch "org.gnome.Rhythmbox3";
      })
    ]
    ++ mediaKeys;

  system.keys = [
    (back 0)
    (button 1 {
      label = "Mic mute";
      icon = icon "status/24/microphone-sensitivity-muted";
      action.keycode = "248";
    })
    (button 2 {
      label = "Lock";
      icon = icon "actions/32/system-lock-screen";
      action.keycode = "Leftmeta-L";
    })
    (button 3 {
      label = "Settings";
      icon = icon "apps/48/preferences-system";
      action.exec = launch "systemsettings";
    })
    # Blanks the deck until the next key press.
    (button 4 {
      label = "Deck off";
      icon = icon "actions/24/brightness-low";
      action.device = "sleep";
    })

    (button 5 {
      label = "Dimmer";
      icon = icon "actions/24/brightness-low";
      action.device = "brightness-10";
    })
    (button 6 {
      label = "Brighter";
      icon = icon "actions/24/brightness-high";
      action.device = "brightness+10";
    })
    (button 7 {
      label = "Screenshot";
      icon = icon "apps/48/spectacle";
      action.keycode = "Leftmeta-Leftshift-Num4";
    })
  ];
}
