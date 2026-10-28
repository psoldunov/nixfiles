# Draws the Stream Deck weather keys from the Open-Meteo forecast and air
# quality APIs (https://open-meteo.com/en/docs), which need no API key.
#
#   deckmaster-weather icon KEY   print the path of KEY's current image
#   deckmaster-weather refresh    fetch the forecast now and redraw every key
#
# KEY is `main`, the key on the main page, or a key of the weather page: now,
# feels, humidity, wind, today, rain, uv, sun, air, or day1 to day5.
# LATITUDE and LONGITUDE pick the place. ICONS is a directory that holds every
# Breeze weather icon as a data: URI, in a file named after the icon, because
# librsvg loads no external image into an SVG read from stdin.
#
# `icon` is each key's iconCommand, which deckmaster runs inside its update
# loop, so it runs only builtins: it prints the image path that the last
# drawing recorded for KEY. Once TTL seconds have passed since the last fetch,
# it also starts `refresh` in the background, with every stream detached so
# that deckmaster does not wait for it. `refresh` draws all keys at once into
# files named after the fetch time, because deckmaster reloads an icon only
# when the printed path changes. A failed fetch is tried again after RETRY
# seconds, and once the forecast on the keys is older than STALE_AFTER seconds
# they get an orange dot. The last refresh writes its errors to $state/log.

readonly ttl=600 retry=60 stale_after=3600
readonly state=${RUNTIME_DIRECTORY:-${XDG_RUNTIME_DIR:?}/deckmaster}/weather
readonly keys=(main now feels humidity wind today rain uv sun air day1 day2 day3 day4 day5)

# Breeze colours, as on the other keys.
readonly text_color='#eff0f1' dim_color='#bdc3c7' blue='#3daee9' green='#27ae60' \
  teal='#1abc9c' yellow='#fdbc4b' orange='#f67400' red='#da4453' purple='#9b59b6'

# Rain chances from this percentage up are highlighted, and dust from this
# many µg/m³ up replaces the air quality caption (Saharan dust reaches Cyprus).
readonly rain_alert=50 dust_alert=50

readonly query="latitude=${LATITUDE:?}&longitude=${LONGITUDE:?}&timezone=auto&timeformat=unixtime"
readonly forecast_url="https://api.open-meteo.com/v1/forecast?$query&forecast_days=6&forecast_hours=24\
&current=temperature_2m,apparent_temperature,relative_humidity_2m,dew_point_2m,weather_code,is_day,\
wind_speed_10m,wind_direction_10m,wind_gusts_10m\
&hourly=precipitation_probability,precipitation\
&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,\
precipitation_probability_max"
readonly air_url="https://air-quality-api.open-meteo.com/v1/air-quality?$query&current=european_aqi,dust"

# Turns the forecast and $air, the air quality response, into one "name<TAB>value"
# line per field the keys show. Times are the place's local time. The rain
# fields cover the next 24 hours; `rain_from` is the first of them whose rain
# chance reaches $alert. Sunrise and sunset are tomorrow's once today's sun
# has set. day0 is today.
# shellcheck disable=SC2016 # jq variables, not shell ones
readonly filter='
  def num: if . == null then "" else round + 0 end;
  def clock($offset): . + $offset | strftime("%H:%M");
  def compass:
    ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
     "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"][(. / 22.5 + 0.5 | floor) % 16];

  .utc_offset_seconds as $offset
  | .current as $current
  | .daily as $days
  | ($air[0].current // {}) as $quality
  | ([.hourly.time, .hourly.precipitation_probability, .hourly.precipitation] | transpose) as $hours
  | (if now > $days.sunset[0] then 1 else 0 end) as $sun
  | {
      temp: ($current.temperature_2m | num),
      feels: ($current.apparent_temperature | num),
      humidity: ($current.relative_humidity_2m | num),
      dew: ($current.dew_point_2m | num),
      code: ($current.weather_code // ""),
      is_day: ($current.is_day // 1),
      wind: ($current.wind_speed_10m | num),
      gusts: ($current.wind_gusts_10m | num),
      wind_from: ($current.wind_direction_10m | if . == null then "" else compass end),
      rain_chance: ([$hours[][1] // 0] | max // 0 | num),
      rain_sum: ([$hours[][2] // 0] | add // 0 | . * 10 | round / 10),
      rain_from: ([$hours[] | select((.[1] // 0) >= $alert)][0][0]
        | if . == null then "" else clock($offset) end),
      uv: ($days.uv_index_max[0] | num),
      sunrise: ($days.sunrise[$sun] | clock($offset)),
      sunset: ($days.sunset[$sun] | clock($offset)),
      daylight: (($days.sunset[$sun] - $days.sunrise[$sun]) / 60 | floor
        | "\(. / 60 | floor)h \(. % 60)m"),
      aqi: ($quality.european_aqi | num),
      dust: ($quality.dust | num)
    }
    + ([range(0; 6) as $i | {
        ("day\($i)_name"): ($days.time[$i] + $offset | strftime("%a")),
        ("day\($i)_code"): ($days.weather_code[$i] // ""),
        ("day\($i)_max"): ($days.temperature_2m_max[$i] | num),
        ("day\($i)_min"): ($days.temperature_2m_min[$i] | num),
        ("day\($i)_rain"): ($days.precipitation_probability_max[$i] | num)
      }] | add)
  | to_entries[]
  | "\(.key)\t\(.value)"
'

# Sets `symbol` to the Breeze icon and `condition` to a short name for a WMO
# weather code. DAY is 1 by day and 0 by night, for the icons with a night
# variant. The names fit the 64 px key at 10 px.
describe() {
  local code=$1 day=$2 time=day night=-night
  if ((day)); then
    night=""
  else
    time=night
  fi
  case $code in
    0) condition=Clear symbol=weather-clear$night ;;
    1) condition='Few clouds' symbol=weather-few-clouds$night ;;
    2) condition=Cloudy symbol=weather-clouds$night ;;
    3) condition=Overcast symbol=weather-overcast ;;
    45 | 48) condition=Fog symbol=weather-fog ;;
    51 | 53 | 55) condition=Drizzle symbol=weather-showers-scattered-$time ;;
    56 | 57) condition='Icy drizzle' symbol=weather-freezing-scattered-rain-$time ;;
    61) condition='Light rain' symbol=weather-showers-scattered-$time ;;
    63) condition=Rain symbol=weather-showers-$time ;;
    65) condition='Heavy rain' symbol=weather-showers-$time ;;
    66 | 67) condition='Icy rain' symbol=weather-freezing-rain-$time ;;
    71) condition='Light snow' symbol=weather-snow-scattered-$time ;;
    73 | 77) condition=Snow symbol=weather-snow-$time ;;
    75) condition='Heavy snow' symbol=weather-snow-$time ;;
    80) condition=Showers symbol=weather-showers-scattered-$time ;;
    81) condition=Showers symbol=weather-showers-$time ;;
    82) condition=Downpour symbol=weather-showers-$time ;;
    85 | 86) condition=Snow symbol=weather-snow-scattered-$time ;;
    95) condition=Storm symbol=weather-storm-$time ;;
    96 | 99) condition='Hail storm' symbol=weather-hail ;;
    *) condition='' symbol=weather-none-available ;;
  esac
}

# An <image> of the Breeze icon NAME, SIZE px square at X, Y. Breeze draws
# overcast skies in dark grey, which vanishes on the black key, so those icons
# go through the `lift` filter that `paint` defines.
symbol_image() {
  local name=$1 x=$2 y=$3 size=$4 uri lift=""
  [[ -e $ICONS/$name ]] || name=weather-none-available
  read -r uri <"$ICONS/$name"
  case $name in
    weather-overcast | weather-many-clouds) lift=' filter="url(#lift)"' ;;
  esac
  printf '<image href="%s" x="%s" y="%s" width="%s" height="%s"%s/>\n' "$uri" "$x" "$y" "$size" "$size" "$lift"
}

# The layout of most detail keys: a title, a large value with a smaller unit,
# and a caption. A missing value shows as a dash.
reading() {
  local title=$1 value=$2 unit=$3 caption=$4 color=${5:-$text_color} caption_color=${6:-$dim_color}
  if [[ -z $value ]]; then
    value=– unit=""
  fi
  cat <<SVG
<text x="32" y="13" font-size="10" fill="$dim_color" text-anchor="middle">$title</text>
<text x="32" y="41" font-size="21" font-weight="bold" fill="$color" text-anchor="middle">$value<tspan font-size="12" font-weight="normal">$unit</tspan></text>
<text x="32" y="58" font-size="11" fill="$caption_color" text-anchor="middle">$caption</text>
SVG
}

# Day I of the forecast, 0 for today: its weekday, weather, highest and lowest
# temperature, and rain chance.
forecast_day() {
  local i=$1 title=${f[day${1}_name]} rain=${f[day${1}_rain]} rain_color=$dim_color symbol condition
  if ((i == 0)); then
    title=Today
  fi
  if ((${rain:-0} >= rain_alert)); then
    rain_color=$blue
  fi
  describe "${f[day${i}_code]}" 1
  cat <<SVG
<text x="32" y="11" font-size="10" fill="$dim_color" text-anchor="middle">$title</text>
$(symbol_image "$symbol" 19 13 26)
<text x="32" y="52" font-size="13" text-anchor="middle"><tspan font-weight="bold" fill="$text_color">${f[day${i}_max]}°</tspan><tspan dx="4" fill="$dim_color">${f[day${i}_min]}°</tspan></text>
<text x="32" y="63" font-size="10" fill="$rain_color" text-anchor="middle">Rain ${rain:-–}%</text>
SVG
}

# The SVG body of KEY, from the fields in `f`.
card() {
  local key=$1 symbol condition color=$text_color caption="" caption_color=$dim_color
  case $key in
    main)
      describe "${f[code]}" "${f[is_day]}"
      symbol_image "$symbol" 12 1 40
      printf '<text x="32" y="60" font-size="19" font-weight="bold" fill="%s" text-anchor="middle">%s°</text>\n' \
        "$text_color" "${f[temp]:-–}"
      ;;
    now)
      describe "${f[code]}" "${f[is_day]}"
      symbol_image "$symbol" 17 1 30
      printf '<text x="32" y="47" font-size="19" font-weight="bold" fill="%s" text-anchor="middle">%s°</text>\n' \
        "$text_color" "${f[temp]:-–}"
      printf '<text x="32" y="60" font-size="10" fill="%s" text-anchor="middle">%s</text>\n' \
        "$dim_color" "$condition"
      ;;
    feels) reading 'Feels like' "${f[feels]:+${f[feels]}°}" '' "Actual ${f[temp]}°" ;;
    humidity) reading Humidity "${f[humidity]}" % "Dew ${f[dew]}°" ;;
    wind) reading "Wind ${f[wind_from]}" "${f[wind]}" ' km/h' "Gusts ${f[gusts]}" ;;
    today) forecast_day 0 ;;
    rain)
      if ((f[rain_chance] >= rain_alert)); then
        color=$blue
      fi
      if [[ -n ${f[rain_from]} ]]; then
        caption="From ${f[rain_from]}" caption_color=$blue
      elif [[ ${f[rain_sum]} == 0 ]]; then
        caption=Dry
      else
        caption="${f[rain_sum]} mm"
      fi
      reading 'Rain 24h' "${f[rain_chance]}" % "$caption" "$color" "$caption_color"
      ;;
    uv)
      if [[ -n ${f[uv]} ]]; then
        if ((f[uv] >= 11)); then
          caption=Extreme color=$purple
        elif ((f[uv] >= 8)); then
          caption='Very high' color=$red
        elif ((f[uv] >= 6)); then
          caption=High color=$orange
        elif ((f[uv] >= 3)); then
          caption=Moderate color=$yellow
        else
          caption=Low color=$green
        fi
      fi
      reading 'UV today' "${f[uv]}" '' "$caption" "$color"
      ;;
    sun)
      cat <<SVG
<text x="32" y="12" font-size="10" fill="$dim_color" text-anchor="middle">Sun</text>
<text x="32" y="30" font-size="14" fill="$text_color" text-anchor="middle"><tspan fill="$yellow">↑</tspan> ${f[sunrise]}</text>
<text x="32" y="47" font-size="14" fill="$text_color" text-anchor="middle"><tspan fill="$orange">↓</tspan> ${f[sunset]}</text>
<text x="32" y="60" font-size="10" fill="$dim_color" text-anchor="middle">${f[daylight]}</text>
SVG
      ;;
    air)
      # European Air Quality Index bands.
      if [[ -n ${f[aqi]} ]]; then
        if ((f[aqi] <= 20)); then
          caption=Good color=$green
        elif ((f[aqi] <= 40)); then
          caption=Fair color=$teal
        elif ((f[aqi] <= 60)); then
          caption=Moderate color=$yellow
        elif ((f[aqi] <= 80)); then
          caption=Poor color=$orange
        elif ((f[aqi] <= 100)); then
          caption='Very poor' color=$red
        else
          caption=Extreme color=$purple
        fi
      fi
      if [[ -n ${f[dust]} ]] && ((f[dust] >= dust_alert)); then
        caption="Dust ${f[dust]}" caption_color=$orange
      fi
      reading 'Air quality' "${f[aqi]}" '' "$caption" "$color" "$caption_color"
      ;;
    day[1-5]) forecast_day "${key#day}" ;;
  esac
}

# Draws KEY into a new image and records its path for `icon`.
paint() {
  local key=$1 image="$state/$1-$now.png" mark=""
  if [[ -e $state/stale ]]; then
    mark="<circle cx=\"58\" cy=\"6\" r=\"3\" fill=\"$orange\"/>"
  fi
  # deckmaster draws a button without a label at 64 px on the MK.2's 72 px keys.
  rsvg-convert --width 64 --height 64 --output "$image" <<SVG || return
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" font-family="Roboto">
<filter id="lift">
  <feComponentTransfer>
    <feFuncR type="linear" slope="2.4" intercept="0.06"/>
    <feFuncG type="linear" slope="2.4" intercept="0.06"/>
    <feFuncB type="linear" slope="2.4" intercept="0.06"/>
  </feComponentTransfer>
</filter>
$(card "$key")
$mark
</svg>
SVG
  printf '%s\n' "$image" >"$state/$key.key.tmp"
  mv --force "$state/$key.key.tmp" "$state/$key.key"
}

# Draws every key from the saved responses, then drops the older images;
# deckmaster keeps its own copy of the ones it shows.
draw() {
  local output name value key old
  local -A f=()
  output=$(jq --raw-output --argjson alert "$rain_alert" --slurpfile air "$state/air.json" \
    "$filter" "$state/forecast.json") || return
  while IFS=$'\t' read -r name value; do
    f[$name]=$value
  done <<<"$output"

  for key in "${keys[@]}"; do
    paint "$key" || return
  done
  for old in "$state"/*.png; do
    [[ $old == *-"$now".png ]] || rm --force -- "$old"
  done
}

# Downloads URL into the state file NAME, keeping the old file unless the
# response is a JSON object with current conditions.
fetch() {
  local url=$1 file=$state/$2
  local partial=$file.$BASHPID
  if curl --fail --silent --show-error --max-time 20 --output "$partial" "$url" &&
    jq --exit-status .current "$partial" >/dev/null; then
    mv --force "$partial" "$file"
  else
    rm --force -- "$partial"
    return 1
  fi
}

refresh() {
  mkdir --parents "$state"
  exec 2>"$state/log"
  printf -v now '%(%s)T' -1
  printf '%s\n' "$now" >"$state/stamp"

  if fetch "$forecast_url" forecast.json; then
    rm --force -- "$state/stale"
    # The air quality key shows a dash until its data loads.
    if ! fetch "$air_url" air.json && [[ ! -e $state/air.json ]]; then
      printf '{}\n' >"$state/air.json"
    fi
  else
    printf '%s\n' $((now - ttl + retry)) >"$state/stamp"
    # Keep the keys as they are until the forecast they show goes stale, then
    # redraw them once with the stale mark.
    local fetched
    [[ -e $state/forecast.json && -e $state/air.json && ! -e $state/stale ]] || return 1
    fetched=$(stat --format=%Y "$state/forecast.json")
    ((now - fetched > stale_after)) || return 1
    touch "$state/stale"
  fi
  draw
}

icon() {
  local key=$1 stamp=0 image=""
  printf -v now '%(%s)T' -1
  read -r stamp 2>/dev/null <"$state/stamp" || true
  if ((now - stamp >= ttl)); then
    mkdir --parents "$state"
    # Recorded here, so the other keys in this round do not fetch too.
    printf '%s\n' "$now" >"$state/stamp"
    refresh </dev/null >/dev/null 2>&1 &
  fi
  read -r image 2>/dev/null <"$state/$key.key" || true
  printf '%s\n' "$image"
}

case ${1:-} in
  icon) icon "${2:?usage: deckmaster-weather icon KEY}" ;;
  refresh) refresh ;;
  *)
    echo "usage: deckmaster-weather icon KEY | refresh" >&2
    exit 64
    ;;
esac
