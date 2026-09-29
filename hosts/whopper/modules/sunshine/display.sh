# Matches the desktop to a Moonlight client for the length of a stream.
#
#   sunshine-display do     switch the primary output to the client's mode
#   sunshine-display undo   put back the mode and scale saved by `do`
#
# Sunshine runs both as its global prep command, `do` when an app starts and
# `undo` when it quits, with SUNSHINE_CLIENT_WIDTH, SUNSHINE_CLIENT_HEIGHT and
# SUNSHINE_CLIENT_FPS set from the client's request.
#
# CUSTOM_MODES lists modes the monitor does not advertise, as WxH@HZ separated
# by spaces. `do` adds each one the output lacks as a KWin custom mode with
# reduced blanking, which KWin keeps from then on. That covers the Steam Deck
# OLED's 1920x1200 at 90 Hz.
#
# `do` then picks the output's mode of the client's size whose refresh rate is
# nearest the client's frame rate without falling short of it, less half a
# hertz so that a 59.88 Hz mode serves a 60 fps stream. Without one it takes
# the fastest mode of that size. When the output has no mode of the client's
# size, the stream runs at the current mode and nothing changes.
#
# The output keeps its scale for clients 1080 lines tall or more: 1920x1200 at
# the desktop's 1.5 gives the Deck's own 1280x800 layout drawn at 1.5 times the
# pixels. Smaller clients get scale 1, since 1.5 on 1280x800 leaves a desktop
# too small to use.
#
# `do` saves the output's mode and scale to $state before it changes them, and
# only when no saved state exists, so a second `do` or a crash before `undo`
# does not lose the original mode. `undo` removes the state only once the
# output is restored. Run `sunshine-display undo` by hand to recover from a
# stream that ended without one.
#
# A failed mode change in `do` is reported but does not fail the command,
# because Sunshine refuses to start the stream when a prep command fails.

readonly state=${XDG_RUNTIME_DIR:?}/sunshine-display.json
readonly custom_modes=${CUSTOM_MODES-}

# The enabled output that KDE ranks first, as kscreen-doctor's JSON.
primary_output() {
  kscreen-doctor --json |
    jq --compact-output '[.outputs[] | select(.enabled and .connected)] | sort_by(.priority) | first'
}

# Whether the output in $1 has a mode of $2 by $3 within half a hertz of $4.
has_mode() {
  jq --exit-status --argjson width "$2" --argjson height "$3" --argjson hz "$4" '
    any(.modes[]; .size.width == $width and .size.height == $height
      and (.refreshRate - $hz | fabs) < 0.5)' <<<"$1" >/dev/null
}

# Adds each of CUSTOM_MODES that the output in $1 lacks.
add_custom_modes() {
  local -r output=$1
  local name mode width height hz
  name=$(jq --raw-output '.name' <<<"$output")

  for mode in $custom_modes; do
    if [[ ! $mode =~ ^([0-9]+)x([0-9]+)@([0-9]+)$ ]]; then
      echo "sunshine-display: ignoring custom mode '$mode', expected WxH@HZ" >&2
      continue
    fi
    width=${BASH_REMATCH[1]} height=${BASH_REMATCH[2]} hz=${BASH_REMATCH[3]}

    if ! has_mode "$output" "$width" "$height" "$hz"; then
      kscreen-doctor "output.$name.addCustomMode.$width.$height.${hz}000.reduced" ||
        echo "sunshine-display: $name refused custom mode $mode" >&2
    fi
  done
}

apply_client_mode() {
  local -r width=${SUNSHINE_CLIENT_WIDTH:?} height=${SUNSHINE_CLIENT_HEIGHT:?} fps=${SUNSHINE_CLIENT_FPS:?}
  local output name mode scale

  output=$(primary_output)
  if [[ -n $custom_modes ]]; then
    add_custom_modes "$output"
    output=$(primary_output)
  fi

  name=$(jq --raw-output '.name' <<<"$output")
  mode=$(jq --raw-output --argjson width "$width" --argjson height "$height" --argjson fps "$fps" '
    [.modes[] | select(.size.width == $width and .size.height == $height)]
    | (map(select(.refreshRate >= $fps - 0.5)) | min_by(.refreshRate - $fps | fabs)) // max_by(.refreshRate)
    | .id // empty' <<<"$output")

  if [[ -z $mode ]]; then
    echo "sunshine-display: $name has no ${width}x${height} mode, streaming at the current mode" >&2
    return 0
  fi

  if [[ ! -e $state ]]; then
    jq --compact-output '{name, mode: .currentModeId, scale}' <<<"$output" >"$state"
  fi

  scale=1
  if ((height >= 1080)); then
    scale=$(jq --raw-output '.scale' "$state")
  fi

  kscreen-doctor "output.$name.mode.$mode" "output.$name.scale.$scale" ||
    echo "sunshine-display: could not switch $name to mode $mode, streaming at the current mode" >&2
}

restore_mode() {
  local name mode scale

  if [[ ! -e $state ]]; then
    return 0
  fi

  name=$(jq --raw-output '.name' "$state")
  mode=$(jq --raw-output '.mode' "$state")
  scale=$(jq --raw-output '.scale' "$state")

  kscreen-doctor "output.$name.mode.$mode" "output.$name.scale.$scale"
  rm -f "$state"
}

case ${1-} in
  do) apply_client_mode ;;
  undo) restore_mode ;;
  *)
    echo "usage: sunshine-display do|undo" >&2
    exit 64
    ;;
esac
