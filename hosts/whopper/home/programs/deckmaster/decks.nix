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
  muteIcon,
  usageKey,
  weatherKey,
  pomodoroKey,
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

  # Track controls, on the bottom row of the Media page.
  playerKeys = [
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
  ];

  # Volume steps, at the right end of the bottom row on the main and Media
  # pages. A tap steps the volume once; holding keeps stepping every 150 ms.
  volumeKeys = [
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

  # Usage bars, one column per mode. `mode` and `fillColor` hold one entry per
  # column, split on `;` (./top-columns.patch). A mode is cpu or memory, or gpu
  # or vram from ./top-gpu.patch.
  top = mode: fillColor: {
    id = "top";
    config = {inherit mode fillColor;};
  };

  # A temperature bar from hwmon through the `temp` widget from
  # ./widget-temp.patch. `sensor` picks it: `chip` is the hwmon name, `sensor`
  # the temp*_label (left out for an unlabelled one), and `device` a part of the
  # chip's resolved sysfs device path, for chips that exist more than once.
  # `warn` and `crit` in °C turn the bar orange and red; they default to the
  # sensor's own temp*_max and temp*_crit, and the bar fills towards `crit`.
  temp = label: sensor: {
    id = "temp";
    config =
      {
        inherit label;
        fillColor = "#1abc9c";
      }
      // sensor;
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
        widget = top "cpu;memory" "#3daee9;#27ae60";
      }
      {
        index = 2;
        widget = top "gpu;vram" "#fdbc4b;#9b59b6";
      }
      # Every temperature sensor worth reading, one per tap. The CPU cores and
      # the NVMe drives' extra sensors are left out; the package and each
      # drive's composite reading sum them up. Thresholds are set here only
      # for sensors that report none (or, for the SATA drives, may not).
      (toggle 3 [
        (temp "CPU" {
          chip = "coretemp";
          sensor = "Package id 0";
        })
        # The NZXT Kraken X53 AIO.
        (temp "Coolant" {
          chip = "x53";
          sensor = "Coolant temp";
          warn = 45;
          crit = 60;
        })
        (temp "GPU" {
          chip = "amdgpu";
          sensor = "edge";
          warn = 85;
        })
        (temp "Hotspot" {
          chip = "amdgpu";
          sensor = "junction";
          warn = 95;
        })
        (temp "VRAM" {
          chip = "amdgpu";
          sensor = "mem";
          warn = 95;
        })
        # The system drive (/) and /NVMe, told apart by PCI address.
        (temp "Kingston" {
          chip = "nvme";
          sensor = "Composite";
          device = "0000:05:00.0";
        })
        (temp "980 Pro" {
          chip = "nvme";
          sensor = "Composite";
          device = "0000:04:00.0";
        })
        # The two Crucial MX500s in the /SATA array, told apart by ATA port.
        # They report through drivetemp, loaded in ../../../modules/boot.nix.
        (temp "SATA 1" {
          chip = "drivetemp";
          device = "/ata5/";
          warn = 55;
          crit = 70;
        })
        (temp "SATA 2" {
          chip = "drivetemp";
          device = "/ata7/";
          warn = 55;
          crit = 70;
        })
        (temp "Wi-Fi" {chip = "iwlwifi_1";})
      ])
      # The weather in Parekklisia from ./weather.nix. A tap opens the weather
      # page, holding the key fetches the forecast again.
      (weatherKey 4 "main" {deck = "weather.deck";})

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
        label = "Media";
        icon = icon "categories/32/applications-multimedia";
        action.deck = "media.deck";
      })
      (button 9 {
        label = "System";
        icon = icon "apps/48/preferences-system";
        action.deck = "system.deck";
      })

      # The pomodoro timer from ./pomodoro.nix. A tap starts, pauses or
      # resumes it; holding the key stops it.
      (pomodoroKey 10)
      # Shows the muted speaker while the default output is muted.
      (button 12 {
        label = "Mute";
        icon = icon "status/24/audio-volume-medium";
        iconCommand = muteIcon {
          muted = icon "status/24/audio-volume-muted";
          unmuted = icon "status/24/audio-volume-medium";
        };
        action.keycode = "Mute";
      })
    ]
    ++ volumeKeys;

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

  # Behind the weather key: the weather now on the top row, today on the middle
  # row and the next five days on the bottom one. A tap on any key closes the
  # page, holding one fetches the forecast again.
  weather.keys = let
    detail = index: name: weatherKey index name {deck = "main.deck";};
  in [
    (back 0)
    (detail 1 "now")
    (detail 2 "feels")
    (detail 3 "humidity")
    # Speed and gusts in km/h, and the compass point the wind blows from.
    (detail 4 "wind")

    (detail 5 "today")
    # The highest rain chance in the next 24 hours, then when rain gets
    # likely or how much falls.
    (detail 6 "rain")
    (detail 7 "uv")
    # Today's sunrise and sunset, or tomorrow's once the sun has set.
    (detail 8 "sun")
    # The European Air Quality Index, or the Saharan dust level when it is
    # high.
    (detail 9 "air")

    (detail 10 "day1")
    (detail 11 "day2")
    (detail 12 "day3")
    (detail 13 "day4")
    (detail 14 "day5")
  ];

  # Icons come from the installed packages the launchers start: ../../packages.nix
  # (Cider, Plexamp), ../../../modules/packages.nix (Rhythmbox) and the plasma6
  # module (Elisa).
  media.keys =
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
        label = "Elisa";
        icon = appIcon pkgs.kdePackages.elisa "elisa";
        action.exec = launch "org.kde.elisa";
      })
      (button 4 {
        label = "Rhythmbox";
        icon = appIcon pkgs.rhythmbox "org.gnome.Rhythmbox3";
        action.exec = launch "org.gnome.Rhythmbox3";
      })
    ]
    ++ playerKeys
    ++ volumeKeys;

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
