# Building blocks for Stream Deck pages, shared by every host that sets
# programs.deckmaster.decks (./default.nix). Widgets and actions follow the
# fork's README: https://github.com/psoldunov/deckmaster#configuration.
#
# Keys are numbered 0-14, left to right and top to bottom:
#
#    0  1  2  3  4
#    5  6  7  8  9
#   10 11 12 13 14
{
  lib,
  pkgs,
  inputs,
}: let
  # Breeze Dark ships for Linux only, but its icons are plain SVGs, so the Macs
  # read the x86_64-linux build, which they fetch from cache.nixos.org like
  # any other path; only the rsvg-convert runs below build on the Mac.
  # shortcut: needs that build in the cache, since no Mac builds for Linux;
  # if a bump ever misses it, build it on Whopper or move the Macs to icons
  # that build on Darwin.
  breezeIcons =
    if pkgs.stdenv.hostPlatform.isLinux
    then pkgs.kdePackages.breeze-icons
    else inputs.nixpkgs.legacyPackages.x86_64-linux.kdePackages.breeze-icons;

  breeze = "${breezeIcons}/share/icons/breeze-dark";

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

  # deckmaster splits `exec` on spaces and runs it without a shell, so every
  # command becomes a script whose store path has none.
  run = name: script: "${pkgs.writeShellScript "deckmaster-${name}" script}";

  # A labelled button. `hold` fires once the key is held for 350 ms. With
  # `iconCommand`, `icon` is only the first frame and the key is repainted
  # every `interval` ms.
  button = index: {
    label,
    icon,
    action,
    hold ? null,
    iconCommand ? null,
    interval ? 500,
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
        // lib.optionalAttrs (iconCommand != null) {inherit interval;};
    }
    // lib.optionalAttrs (hold != null) {action_hold = hold;};

  back = index:
    button index {
      label = "Back";
      icon = icon "actions/32/go-previous";
      action.deck = "main.deck";
    };

  # A key showing the weather from Open-Meteo.
  weatherKey = import ./weather.nix {inherit lib pkgs button icon breeze;};
in {
  inherit breeze svgIcon icon run button back weatherKey;

  # A key that shows the first of `widgets` and switches to the next on a tap,
  # through the fork's `toggle` widget. The key takes no action of its own,
  # since an action would replace the switch.
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
  # column, split on `;`. A mode is cpu or memory, or, on Linux only, gpu or
  # vram.
  top = mode: fillColor: {
    id = "top";
    config = {inherit mode fillColor;};
  };

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

  # Behind the weather key: the weather now on the top row, today on the middle
  # row and the next five days on the bottom one. A tap on any key closes the
  # page, holding one fetches the forecast again.
  weatherPage = let
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

  # A key showing Claude Code or Codex plan usage from Token Station.
  usageKey = import ./usage.nix {inherit lib pkgs button svgIcon;};

  # A key for the Clokkr time tracker. `clokkr` provides the `clokkr` CLI and
  # `placeholder` is the image shown until the first drawing.
  clokkrKey = {
    clokkr,
    placeholder,
  }:
    import ./clokkr.nix {inherit lib pkgs inputs button clokkr placeholder;};
}
