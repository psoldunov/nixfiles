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
  button,
  icon,
  launch,
}: {
  main.keys = [
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
      icon = icon "apps/64/utilities-terminal";
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
      label = "Screenshot";
      icon = icon "apps/48/spectacle";
      action.keycode = "Leftmeta-Leftshift-Num4";
    })
    (button 9 {
      label = "System";
      icon = icon "apps/48/preferences-system";
      action.deck = "system.deck";
    })

    (button 10 {
      label = "Previous";
      icon = icon "actions/32/media-skip-backward";
      action.keycode = "Previoussong";
    })
    (button 11 {
      label = "Play/Pause";
      icon = icon "actions/32/media-playback-start";
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

  system.keys = [
    (button 0 {
      label = "Back";
      icon = icon "actions/32/go-previous";
      action.deck = "main.deck";
    })
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
  ];
}
