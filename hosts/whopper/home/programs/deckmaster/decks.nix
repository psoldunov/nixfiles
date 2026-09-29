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
  usageKey,
}: let
  back = index:
    button index {
      label = "Back";
      icon = icon "actions/32/go-previous";
      action.deck = "main.deck";
    };

  # A launcher on the Apps page. It also returns to the main page, so the page
  # closes like a folder once the app starts.
  app = index: {
    label,
    icon,
    desktopId,
  }:
    button index {
      inherit label icon;
      action = {
        exec = launch desktopId;
        deck = "main.deck";
      };
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
    # A tap steps the volume once; holding keeps stepping every 150 ms.
    (button 13 {
      label = "Vol -";
      icon = icon "status/24/audio-volume-low";
      action = {
        keycode = "Volumedown";
        repeat = 150;
      };
    })
    (button 14 {
      label = "Vol +";
      icon = icon "status/24/audio-volume-high";
      action = {
        keycode = "Volumeup";
        repeat = 150;
      };
    })
  ];

  # A key that shows the first of `widgets` and switches to the next on a tap,
  # through the `toggle` widget from ./widget-toggle.patch. The key takes no
  # action of its own, since an action would replace the switch.
  toggle = index: widgets: {
    inherit index;
    widget = {
      id = "toggle";
      config = {inherit widgets;};
    };
  };

  # A clock face. `format` and `font` hold one entry per line, split on `;`.
  time = format: font: {
    id = "time";
    config = {inherit format font;};
  };

  # A usage bar. `mode` is cpu or memory, or gpu or vram from ./top-gpu.patch.
  top = mode: fillColor: {
    id = "top";
    config = {inherit mode fillColor;};
  };
in {
  main.keys =
    [
      (toggle 0 [
        (time "%H;%i;%s" "bold;regular;thin")
        (time "%D;%d;%M" "regular;bold;regular")
      ])
      {
        index = 1;
        widget = top "cpu" "#3daee9";
      }
      {
        index = 2;
        widget = top "memory" "#27ae60";
      }
      (toggle 3 [
        (top "gpu" "#fdbc4b")
        (top "vram" "#9b59b6")
      ])
      # wttr.in, located by IP address. Set `location` to pin a city.
      {
        index = 4;
        widget = {
          id = "weather";
          config.unit = "celsius";
        };
      }

      # Plan usage from Token Station. A tap switches the usage window, holding
      # the key refreshes the numbers.
      (usageKey 5 "claude")
      (usageKey 6 "codex")
      (button 7 {
        label = "Apps";
        icon = icon "categories/32/applications-all";
        action.deck = "apps.deck";
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

  apps.keys = [
    (back 0)
    (app 1 {
      label = "Terminal";
      icon = appIcon config.programs.kitty.package "kitty";
      desktopId = "kitty";
    })
    (app 2 {
      label = "Browser";
      icon = icon "apps/48/internet-web-browser";
      desktopId = "zen";
    })
    (app 3 {
      label = "Files";
      icon = icon "apps/64/system-file-manager";
      desktopId = "org.kde.dolphin";
    })
    (app 4 {
      label = "Ensemblr";
      icon = appIcon pkgs.ensemblr-master "ensemblr";
      desktopId = "ensemblr";
    })
  ];

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
