# Stream Deck weather keys from Open-Meteo (https://open-meteo.com), which
# needs no API key. ./weather.sh fetches the forecast and air quality for
# `location` every ten minutes and draws every key from them with the Breeze
# weather icons: the current weather on the main page, and behind it a page
# with the feels-like temperature, humidity, wind, rain, UV index, sunrise and
# sunset, air quality and the next five days. Holding any weather key fetches
# the forecast again.
{
  lib,
  pkgs,
  button,
  icon,
  breeze,
}: let
  # Parekklisia, Limassol.
  location = {
    latitude = "34.7458";
    longitude = "33.1583";
  };

  # Every Breeze weather icon as a data: URI in a file named after the icon,
  # for ./weather.sh to put into the key images.
  icons = pkgs.runCommand "deckmaster-weather-icons" {} ''
    mkdir $out
    for svg in ${breeze}/applets/48/weather-*.svg; do
      name=$(basename $svg .svg)
      if [[ $name != *-symbolic ]]; then
        printf 'data:image/svg+xml;base64,%s\n' "$(base64 --wrap=0 $svg)" > $out/$name
      fi
    done
  '';

  weather = lib.getExe (pkgs.writeShellApplication {
    name = "deckmaster-weather";
    runtimeInputs = [pkgs.coreutils pkgs.curl pkgs.jq pkgs.librsvg];
    runtimeEnv = {
      LATITUDE = location.latitude;
      LONGITUDE = location.longitude;
      ICONS = icons;
    };
    text = builtins.readFile ./weather.sh;
  });
in
  # A key showing `name`, one of the keys ./weather.sh draws, that does `action`
  # on a tap. It has no label, so the drawing fills the key; the placeholder
  # icon shows only until the first forecast arrives. The drawings change every
  # ten minutes at most, so the key looks for a new one every 5 s rather than
  # every 500 ms, which keeps the weather page's fourteen keys from slowing
  # deckmaster's update loop.
  index: name: action:
    button index {
      label = "";
      icon = icon "applets/48/weather-none-available";
      iconCommand = "${weather} icon ${name}";
      interval = 5000;
      inherit action;
      hold.exec = "${weather} refresh";
    }
