# Draws the Stream Deck key for Clokkr and drives its timer.
#
#   deckmaster-clokkr icon     print the path of the key's current image
#   deckmaster-clokkr toggle   pause the running timer or start the current
#                              task; with no task to start, open the popover
#   deckmaster-clokkr open     open the timer popover to pick a task
#
# MARK_FILE names a file with the shapes of Clokkr's symbolic icon (./clokkr.nix).
#
# `icon` is the key's iconCommand. deckmaster runs it every 500 ms inside its
# update loop, and a slow command delays key presses. So it reads the state
# with a single `clokkr status` call, which takes a couple of milliseconds,
# and draws only when something on the key changed: once a second while the
# timer runs, not at all while it is paused or stopped. The record keeps what
# the current image shows. Every drawing gets a new file name, because
# deckmaster reloads an icon only when the printed path changes.

dir=${RUNTIME_DIRECTORY:-${XDG_RUNTIME_DIR:?}/deckmaster}
readonly dir record=$dir/clokkr.key

# Breeze colours, as on the pomodoro key. A running task's mark takes the
# task's own colour, or the blue for a task without a valid one.
readonly text_color='#eff0f1' dim_color='#bdc3c7' paused_color='#f67400' task_color='#3daee9'

# The fields `icon` reads from `clokkr status`, split on the unit separator.
readonly sep=$'\x1f'
readonly template="{state}$sep{elapsed}$sep{task_today}$sep{today}$sep{task}$sep{color}"

# Text that goes into the SVG as-is.
escape() {
  local text=$1
  text=${text//'&'/'&amp;'}
  text=${text//'<'/'&lt;'}
  printf '%s' "${text//'>'/'&gt;'}"
}

# Sets `clock` to an HH:MM:SS duration as the key shows it: MM:SS under an
# hour, H:MM:SS from then on.
set_clock() {
  clock=$1
  if [[ $clock == 00:* ]]; then
    clock=${clock#00:}
  else
    clock=${clock#0}
  fi
}

# Draws the key into $dir and sets `image` to its path. deckmaster draws a
# button without a label at 64 px on the MK.2's 72 px keys.
render() {
  local mark_color=$1 mark_opacity=$2 label=$3 label_color=$4 clock=$5 clock_color=$6 caption=$7
  local size=16 shapes
  # H:MM:SS takes a smaller face to fit the key.
  ((${#clock} <= 5)) || size=13
  read -r -d '' shapes <"$MARK_FILE" || true

  mkdir --parents "$dir"
  image="$dir/clokkr-${EPOCHREALTIME/./}.png"
  rsvg-convert --width 64 --height 64 --output "$image.tmp" <<SVG || return
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" font-family="Roboto">
  <g transform="translate(3 3) scale(1.125)" fill="$mark_color" fill-opacity="$mark_opacity">
    $shapes
  </g>
  <text x="62" y="15" font-size="10" fill="$label_color" text-anchor="end">$(escape "$label")</text>
  <text x="32" y="40" font-size="$size" font-weight="bold" fill="$clock_color" text-anchor="middle">$(escape "$clock")</text>
  <text x="32" y="58" font-size="10" fill="$dim_color" text-anchor="middle">$(escape "$caption")</text>
</svg>
SVG
  mv --force "$image.tmp" "$image" || return

  # Drop the images the key showed before; deckmaster keeps its own copy.
  local old stale=()
  for old in "$dir"/clokkr-*.png; do
    [[ $old == "$image" ]] || stale+=("$old")
  done
  ((${#stale[@]} == 0)) || rm --force -- "${stale[@]}"
}

icon() {
  local line state="" elapsed="" task_today="" today="" task="" color=""
  if line=$(clokkr status --format "$template" 2>/dev/null); then
    IFS=$sep read -r state elapsed task_today today task color <<<"$line"
  fi
  [[ $color =~ ^#[[:xdigit:]]{6}$ ]] || color=$task_color

  local mark_color=$dim_color mark_opacity=1 label="" label_color=$dim_color
  local clock="" clock_color=$dim_color caption=$task
  case $state in
    running)
      mark_color=$color clock_color=$text_color
      set_clock "$elapsed"
      ;;
    paused)
      mark_color=$paused_color label=Paused label_color=$paused_color
      set_clock "$task_today"
      ;;
    stopped)
      label=Today caption=Start
      set_clock "$today"
      ;;
    # The daemon could not be reached.
    *) mark_opacity=0.5 clock=Offline caption="" ;;
  esac
  # About as many characters as fit across the key at this size.
  ((${#caption} <= 11)) || caption="${caption:0:10}…"

  local shown="$mark_color|$mark_opacity|$label|$clock|$clock_color|$caption" drawn="" image=""
  { IFS= read -r drawn && IFS= read -r image; } 2>/dev/null <"$record" || true
  if [[ $drawn == "$shown" ]]; then
    printf '%s\n' "$image"
    return
  fi

  render "$mark_color" "$mark_opacity" "$label" "$label_color" "$clock" "$clock_color" "$caption" ||
    image=""
  # Recorded even when drawing failed, so a failure is retried only once the
  # key has something new to show.
  printf '%s\n%s\n' "$shown" "$image" >"$record"
  printf '%s\n' "$image"
}

open() {
  clokkr ui popover
}

toggle() {
  local status=0
  clokkr toggle >/dev/null || status=$?
  # The daemon refuses (exit 3) to start a stopped timer with no task picked.
  if ((status == 3)); then
    open
  else
    return "$status"
  fi
}

case ${1:-} in
  icon) icon ;;
  toggle) toggle ;;
  open) open ;;
  *)
    echo "usage: deckmaster-clokkr icon | toggle | open" >&2
    exit 64
    ;;
esac
