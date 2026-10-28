# BigMac's Stream Deck pages for programs.deckmaster.decks, laid out like
# Whopper's (hosts/whopper/home/programs/deckmaster/decks.nix) so the keys sit
# in the same places. Each attribute becomes <name>.deck; deckmaster opens
# `main` first. The key numbering and the shared helpers (`deck`) are in
# modules/home/programs/deckmaster/lib.nix.
#
# Widgets and actions follow https://github.com/psoldunov/deckmaster#configuration.
# `keycode` takes the Linux key names, which the fork maps to Mac keys:
# `Leftmeta` is Command, and the media keys act like an Apple keyboard's.
#
# Whopper's GPU and temperature keys (2, 3) read Linux's sysfs and its
# pomodoro key (10) runs on Plasma and systemd, so those slots stay empty here.
{
  deck,
  launch,
  appIcon,
  micMute,
  clokkrKey,
}: let
  inherit (deck) button icon back toggle time top volumeKeys usageKey weatherKey;

  # A key that starts the app bundle at `app` and shows its icon. `extra` adds
  # to the action.
  launcher = index: {
    label,
    app,
    fallback,
    extra ? {},
  }:
    button index ({
        inherit label;
        action = {exec = launch app;} // extra;
      }
      // appIcon app fallback);

  # A launcher on the Apps page. It also returns to the main page, so the page
  # closes like a folder once the app starts.
  app = index: args: launcher index (args // {extra.deck = "main.deck";});

  media = icon "categories/32/applications-multimedia";
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
      # The weather in Parekklisia. A tap opens the weather page, holding the
      # key fetches the forecast again.
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

      # The Clokkr timer. A tap pauses it or starts the current task; holding
      # the key opens the popover to pick a task.
      (clokkrKey 11)
      # Unlike Whopper's, the icon does not follow the mute state: osascript
      # takes ~150 ms, too slow for an iconCommand inside deckmaster's update
      # loop.
      (button 12 {
        label = "Mute";
        icon = icon "status/24/audio-volume-medium";
        action.keycode = "Mute";
      })
    ]
    ++ volumeKeys;

  apps.keys = [
    (back 0)
    (app 1 {
      label = "Terminal";
      app = "/Applications/Ghostty.app";
      fallback = icon "apps/48/utilities-terminal";
    })
    (app 2 {
      label = "Browser";
      app = "/Applications/Zen.app";
      fallback = icon "apps/48/internet-web-browser";
    })
    (app 3 {
      label = "Files";
      app = "/System/Library/CoreServices/Finder.app";
      fallback = icon "apps/64/system-file-manager";
    })
    (app 4 {
      label = "Ensemblr";
      app = "/Applications/Ensemblr.app";
      fallback = icon "apps/48/utilities-terminal";
    })
  ];

  weather.keys = deck.weatherPage;

  media.keys =
    [
      (back 0)
      (launcher 1 {
        label = "Music";
        app = "/System/Applications/Music.app";
        fallback = media;
      })
      (launcher 2 {
        label = "Plexamp";
        app = "/Applications/Plexamp.app";
        fallback = media;
      })
      (launcher 3 {
        label = "Infuse";
        app = "/Applications/Infuse.app";
        fallback = media;
      })

      # Track controls. The media keys act on whichever app macOS's Now
      # Playing shows.
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
    ]
    ++ volumeKeys;

  system.keys = [
    (back 0)
    (button 1 {
      label = "Mic mute";
      icon = icon "status/24/microphone-sensitivity-muted";
      action.exec = micMute;
    })
    # Control-Command-Q, macOS's lock screen shortcut.
    (button 2 {
      label = "Lock";
      icon = icon "actions/32/system-lock-screen";
      action.keycode = "Leftctrl-Leftmeta-Q";
    })
    (button 3 {
      label = "Settings";
      icon = icon "apps/48/preferences-system";
      action.exec = launch "System Settings";
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
    # Shift-Command-4, a region capture.
    (button 7 {
      label = "Screenshot";
      icon = icon "apps/48/spectacle";
      action.keycode = "Leftmeta-Leftshift-Num4";
    })
  ];
}
