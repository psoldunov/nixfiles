# Draws the Stream Deck keys for Claude Code and Codex plan usage from the
# snapshot Token Station publishes on the session bus (docs/dbus-api.md in its
# repository), and switches the usage window each key shows.
#
#   deckmaster-usage icon PROVIDER LOGO   print the path of the key's current image
#   deckmaster-usage next PROVIDER        show the provider's next usage window
#   deckmaster-usage refresh              refresh Token Station, then redraw
#
# PROVIDER is a Token Station provider id (claude, codex). LOGO is a file that
# holds the provider's logo as a data: URI, because librsvg loads no external
# image into an SVG read from stdin.
#
# `icon` is the key's iconCommand. deckmaster runs it every 500 ms inside its
# update loop, and a slow command delays key presses. So the common path runs
# only builtins: it prints the cached image path again until TTL seconds have
# passed since it last read the snapshot, the selected window has changed, or a
# refresh has started or ended. Only then does it read the snapshot again and
# draw a new image if anything on the key changed. The image
# file name encodes everything the image shows, because deckmaster reloads an
# icon only when the printed path changes.

readonly ttl=10
readonly bus=(dev.soldunov.TokenStation /dev/soldunov/TokenStation dev.soldunov.TokenStation1)
dir=${RUNTIME_DIRECTORY:-${XDG_RUNTIME_DIR:?}/deckmaster}

# Breeze colours, as on the CPU key and in the Token Station tray.
readonly text_color='#eff0f1' dim_color='#bdc3c7'
declare -A level_colors=([normal]='#3daee9' [warning]='#f67400' [critical]='#da4453')

# One line each: the provider's state, its window ids, then the shown window's
# short label, percent used, reset time and level. The shown window is the
# selected one, or the first while nothing valid is selected. The label has to
# fit beside the logo in 7 characters: "Weekly · Fable" becomes "Fable", a model
# slug like "Weekly · gpt-5.3-codex-spark" keeps its last part, "spark".
# shellcheck disable=SC2016 # jq variables, not shell ones
readonly filter='
  .data | fromjson | .providers[] | select(.id == $provider)
  | (.windows // []) as $windows
  | (($windows | map(select(.id == $selected)) | first) // $windows[0] // {}) as $w
  | .state,
    ($windows | map(.id) | join(" ")),
    ($w.label // "" | split(" · ") | last // ""
      | sub("-hour window$"; "h") | sub("-day window$"; "d")
      | if length > 7 then split("-") | last else . end
      | if length > 7 then .[:6] + "…" else . end),
    ($w.usedPercent | if . == null then "" else round end),
    ($w.resetsAt // ""),
    ($w.level // "normal")
'

# Text that goes into the SVG as-is.
escape() {
  local text=$1
  text=${text//'&'/'&amp;'}
  text=${text//'<'/'&lt;'}
  printf '%s' "${text//'>'/'&gt;'}"
}

# Time left until a Unix timestamp, e.g. "45m", "2h 13m" or "3d 4h".
countdown() {
  local left=$(($1 - now))
  if ((left < 60)); then
    printf 'now'
  elif ((left < 3600)); then
    printf '%dm' $((left / 60))
  elif ((left < 86400)); then
    printf '%dh %dm' $((left / 3600)) $((left % 3600 / 60))
  else
    printf '%dd %dh' $((left / 86400)) $((left % 86400 / 3600))
  fi
}

# Draws the key for the given fields into $dir and sets `image` to its path.
# deckmaster draws a button without a label at 64 px on the MK.2's 72 px keys.
render() {
  local provider=$1 logo=$2 state=$3 label=$4 percent=$5 resets_at=$6 level=$7 busy=$8
  local message="" caption="" caption_color=$dim_color

  case $state in
    ok) ;;
    stale) caption=Stale caption_color=${level_colors[warning]} ;;
    loading) message=Loading ;;
    unauthenticated) message='Sign in' ;;
    not_installed) message='No CLI' ;;
    disabled) message=Off ;;
    error) message=Error ;;
    *) message=Offline ;;
  esac
  if [[ -z $message && -z $percent ]]; then
    message='No limits'
  fi
  if [[ -z $caption && -n $resets_at ]]; then
    caption=$(countdown "$resets_at")
  fi
  if ((busy)); then
    caption=Refreshing caption_color=$dim_color
  fi
  [[ -v "level_colors[$level]" ]] || level=normal

  local name="$provider-$state-$label-$percent-$level-$caption-$message"
  image="$dir/${name//[^[:alnum:].-]/_}.png"
  if [[ -e $image ]]; then
    return
  fi

  local color=${level_colors[$level]} logo_opacity=1 body
  if [[ -n $message ]]; then
    logo_opacity=0.5
    body="<text x=\"32\" y=\"44\" font-size=\"13\" font-weight=\"bold\" fill=\"$text_color\" text-anchor=\"middle\">$(escape "$message")</text>"
  else
    local width=$((percent > 100 ? 56 : percent * 56 / 100)) number_color=$text_color
    [[ $level == normal ]] || number_color=$color
    body="<text x=\"32\" y=\"41\" font-size=\"22\" font-weight=\"bold\" fill=\"$number_color\" text-anchor=\"middle\">$percent<tspan font-size=\"13\">%</tspan></text>
  <rect x=\"4\" y=\"45\" width=\"56\" height=\"5\" rx=\"2.5\" fill=\"$text_color\" fill-opacity=\"0.2\"/>
  <rect x=\"4\" y=\"45\" width=\"$width\" height=\"5\" rx=\"2.5\" fill=\"$color\"/>"
  fi

  local logo_uri
  read -r logo_uri <"$logo"
  rsvg-convert --width 64 --height 64 --output "$image.tmp" <<SVG || return
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" font-family="Roboto">
  <image href="$logo_uri" x="3" y="3" width="18" height="18" opacity="$logo_opacity"/>
  <text x="62" y="15" font-size="11" fill="$dim_color" text-anchor="end">$(escape "$label")</text>
  $body
  <text x="32" y="62" font-size="12" fill="$caption_color" text-anchor="middle">$(escape "$caption")</text>
</svg>
SVG
  mv --force "$image.tmp" "$image" || return

  # Drop the images this key showed before; deckmaster keeps its own copy.
  local old stale=()
  for old in "$dir/$provider"-*.png; do
    [[ $old == "$image" ]] || stale+=("$old")
  done
  ((${#stale[@]} == 0)) || rm --force -- "${stale[@]}"
}

icon() {
  local provider=$1 logo=$2
  local record="$dir/$provider.key" selected="" busy=0 stamp cached_busy image requested
  printf -v now '%(%s)T' -1
  read -r selected 2>/dev/null <"$dir/$provider.window" || true
  [[ ! -e $dir/refreshing ]] || busy=1

  # The record is "time|busy|image|selected window" of the last drawing.
  if IFS='|' read -r stamp cached_busy image requested 2>/dev/null <"$record" &&
    ((now - stamp < ttl && cached_busy == busy)) && [[ $requested == "$selected" ]]; then
    printf '%s\n' "$image"
    return
  fi

  mkdir --parents "$dir"
  local snapshot fields=()
  if snapshot=$(busctl --user --timeout=2 --json=short get-property "${bus[@]}" Snapshot 2>/dev/null); then
    mapfile -t fields < <(jq --raw-output --arg provider "$provider" --arg selected "$selected" "$filter" <<<"$snapshot")
  fi
  printf '%s\n' "${fields[1]:-}" >"$dir/$provider.windows"

  render "$provider" "$logo" "${fields[0]:-offline}" "${fields[2]:-}" "${fields[3]:-}" \
    "${fields[4]:-}" "${fields[5]:-normal}" "$busy" || image=""
  # Recorded even when drawing failed, so a failure is retried once per TTL.
  printf '%s|%s|%s|%s\n' "$now" "$busy" "$image" "$selected" >"$record"
  printf '%s\n' "$image"
}

next() {
  local provider=$1 selected="" ids=() i index=0
  read -r selected 2>/dev/null <"$dir/$provider.window" || true
  read -r -a ids 2>/dev/null <"$dir/$provider.windows" || true
  ((${#ids[@]} > 1)) || return 0

  for i in "${!ids[@]}"; do
    [[ ${ids[i]} != "$selected" ]] || index=$i
  done
  printf '%s\n' "${ids[(index + 1) % ${#ids[@]}]}" >"$dir/$provider.window"
}

refresh() {
  mkdir --parents "$dir"
  touch "$dir/refreshing"
  busctl --user --timeout=60 call "${bus[@]}" Refresh || true
  # Redraw every key from the new snapshot now instead of after the TTL.
  rm --force -- "$dir/refreshing" "$dir"/*.key
}

case ${1:-} in
  icon) icon "$2" "$3" ;;
  next) next "$2" ;;
  refresh) refresh ;;
  *)
    echo "usage: deckmaster-usage icon PROVIDER LOGO | next PROVIDER | refresh" >&2
    exit 64
    ;;
esac
