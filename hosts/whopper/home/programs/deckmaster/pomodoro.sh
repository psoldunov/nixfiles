# Runs the Stream Deck pomodoro timer and draws its key.
#
#   deckmaster-pomodoro icon     print the path of the key's current image
#   deckmaster-pomodoro toggle   start, pause or resume the current phase
#   deckmaster-pomodoro stop     stop the phase; on a stopped timer, clear the
#                                count of finished focus phases
#   deckmaster-pomodoro elapse   end the running phase (run by its timer)
#
# A focus phase runs FOCUS_MINUTES. When it ends, a break starts on its own:
# LONG_BREAK_MINUTES after every SESSIONS-th focus phase, BREAK_MINUTES
# otherwise. When a break ends, the next focus phase starts on its own too, so
# the phases cycle until a hold stops the timer. Every phase end posts a
# notification and plays a sound from SOUNDS.
#
# A running focus phase turns on Plasma's Do Not Disturb until the phase's
# end, so it lifts on time even if nothing clears it. Pausing, stopping or
# finishing the phase lifts it early.
#
# deckmaster repaints only the page on screen and stops while the deck sleeps,
# so the key cannot be what notices a phase end. Each running phase gets a
# transient systemd timer instead (deckmaster-pomodoro-*.timer) that runs
# `elapse` at the phase's end on the wall clock, so it also fires right after a
# suspend that slept through it. Pausing or stopping removes the timer.
#
# The state lives in $XDG_RUNTIME_DIR/deckmaster-pomodoro rather than in the
# daemon's RuntimeDirectory, so a running phase survives a daemon restart. The
# state file holds one line, "status phase value finished": status is idle,
# running or paused; phase is focus, break or long; value is the end time as a
# Unix timestamp while running and the seconds left while paused; finished
# counts the focus phases since the last long break.
#
# `icon` is the key's iconCommand. deckmaster runs it every 500 ms inside its
# update loop, and a slow command delays key presses. So it reads the state
# with builtins only and draws a new image only when what the key shows has
# changed, at most once a second. The image file name encodes everything the
# image shows, because deckmaster reloads an icon only when the printed path
# changes.

dir=${XDG_RUNTIME_DIR:?}/deckmaster-pomodoro
readonly dir state_file=$dir/state unit=deckmaster-pomodoro

# Breeze colours: red for focus, green for a break, blue for the long break.
readonly text_color='#eff0f1' dim_color='#bdc3c7' paused_color='#f67400'
declare -A phase_colors=([focus]='#da4453' [break]='#27ae60' [long]='#3daee9')
declare -A phase_labels=([focus]=Focus [break]=Break [long]='Long break')
declare -A phase_minutes=([focus]=$FOCUS_MINUTES [break]=$BREAK_MINUTES [long]=$LONG_BREAK_MINUTES)

# The progress ring's radius and its circumference, both in px.
readonly radius=29 ring=182

status=idle phase=focus value=0 finished=0 now=0

# Reads the state file. A missing or damaged one reads as a fresh timer.
load() {
  read -r status phase value finished 2>/dev/null <"$state_file" || true
  case $status in
    idle | running | paused) ;;
    *) status=idle ;;
  esac
  [[ -v "phase_colors[$phase]" ]] || phase=focus
  [[ $value =~ ^[0-9]+$ ]] || value=0
  [[ $finished =~ ^[0-9]+$ ]] || finished=0
  printf -v now '%(%s)T' -1
}

save() {
  printf '%s %s %s %s\n' "$status" "$phase" "$value" "$finished" >"$state_file.tmp"
  mv --force "$state_file.tmp" "$state_file"
}

# Serialises the commands that change the state, so a tap cannot race the
# timer ending the phase.
lock() {
  mkdir --parents "$dir"
  exec 9>"$dir/lock"
  flock 9
}

# Posts a notification and plays a sound. Neither is worth failing a phase
# change over, so a failure only reaches the journal.
announce() {
  local sound=$1 summary=$2 body=$3
  notify-send --app-name=Pomodoro --icon=chronometer "$summary" "$body" ||
    echo "Can't post the notification: $summary" >&2
  if [[ -n $sound ]]; then
    pw-play "$SOUNDS/$sound.oga" || echo "Can't play $sound" >&2
  fi
}

# Do Not Disturb, set the way Plasma's notifications applet sets it: an end
# time in plasmanotifyrc, which plasmashell reloads on --notify. The value
# written is kept in $dir/dnd, so only that one is ever cleared and a Do Not
# Disturb the user set stays.
readonly dnd_key=(--file plasmanotifyrc --group DoNotDisturb --key Until)

# Seconds since the epoch for a KConfig date-time, stored either as a list
# ("2026,10,7,14,48,16") or in ISO 8601.
kconfig_time() {
  local year month day hour minute second
  if [[ $1 == *T* ]]; then
    date --date="$1" +%s
  else
    IFS=, read -r year month day hour minute second _ <<<"$1"
    date --date="$year-$month-$day $hour:$minute:${second:-0}" +%s
  fi
}

# Turns Do Not Disturb on until `end`, unless one the user set lasts longer.
quiet() {
  local end=$1 current ours theirs
  current=$(kreadconfig6 "${dnd_key[@]}")
  read -r ours 2>/dev/null <"$dir/dnd" || ours=""
  if [[ -n $current && $current != "$ours" ]]; then
    theirs=$(kconfig_time "$current" 2>/dev/null) || theirs=0
    if ((theirs >= end)); then
      return 0
    fi
  fi
  ours=$(date --date="@$end" '+%Y,%-m,%-d,%-H,%-M,%-S')
  kwriteconfig6 --notify "${dnd_key[@]}" "$ours"
  printf '%s\n' "$ours" >"$dir/dnd"
}

# Lifts the Do Not Disturb that `quiet` set, if it is still in place.
unquiet() {
  local ours current
  read -r ours 2>/dev/null <"$dir/dnd" || return 0
  rm --force -- "$dir/dnd"
  current=$(kreadconfig6 "${dnd_key[@]}")
  if [[ $current == "$ours" ]]; then
    kwriteconfig6 --notify --delete "${dnd_key[@]}"
  fi
}

# Waits up to 2 s for plasmashell to act on `unquiet`, so the notification
# that ends a focus phase is not held back by the Do Not Disturb it lifts.
await_unquiet() {
  local i inhibited
  for ((i = 0; i < 10; i++)); do
    inhibited=$(busctl --user get-property org.freedesktop.Notifications \
      /org/freedesktop/Notifications org.freedesktop.Notifications Inhibited 2>/dev/null) || return 0
    [[ $inhibited == 'b true' ]] || return 0
    sleep 0.2
  done
}

# Removes the timer of the running phase, if there is one.
unschedule() {
  systemctl --user stop "$unit-*.timer"
}

# Starts `phase` for `seconds` from now: arms its timer, then records it. A
# timer that cannot be armed leaves the state as it was.
start() {
  local next=$1 seconds=$2 end self at
  # A calendar time already past would never elapse.
  ((seconds >= 2)) || seconds=2
  # The clock is read again, as a phase end can spend seconds on a sound or on
  # Do Not Disturb before the next phase starts.
  printf -v now '%(%s)T' -1
  end=$((now + seconds))
  self=$(readlink --canonicalize "$0")
  at=$(date --utc --date="@$end" '+%Y-%m-%d %H:%M:%S UTC')

  unschedule
  if ! systemd-run --user --quiet --collect --unit="$unit-$end-$$" \
    --on-calendar="$at" --timer-property=AccuracySec=1s \
    --timer-property=RemainAfterElapse=no "$self" elapse; then
    announce "" "Pomodoro" "Can't start the timer: systemd-run failed."
    return 1
  fi
  status=running phase=$next value=$end
  save
  if [[ $next == focus ]]; then
    quiet "$end" || echo "Can't turn on Do Not Disturb" >&2
  fi
}

toggle() {
  lock
  load
  case $status in
    idle) start "$phase" $((phase_minutes[$phase] * 60)) ;;
    paused) start "$phase" "$value" ;;
    running)
      unschedule
      unquiet || echo "Can't lift Do Not Disturb" >&2
      status=paused value=$((value > now ? value - now : 0))
      save
      ;;
  esac
}

stop() {
  lock
  load
  unschedule
  unquiet || echo "Can't lift Do Not Disturb" >&2
  # A second stop clears the count, and so does leaving the long break, which
  # closes the round.
  if [[ $status == idle || $phase == long ]]; then
    finished=0
  fi
  status=idle phase=focus value=0
  save
}

elapse() {
  lock
  load
  # A timer that outlived its phase, which was paused or stopped meanwhile.
  if [[ $status != running ]] || ((now + 2 < value)); then
    return 0
  fi

  if [[ $phase == focus ]]; then
    unquiet || echo "Can't lift Do Not Disturb" >&2
    await_unquiet
    finished=$((finished + 1))
    if ((finished >= SESSIONS)); then
      if start long $((LONG_BREAK_MINUTES * 60)); then
        announce complete "Long break" "$finished focus sessions done. Back in $LONG_BREAK_MINUTES minutes."
        return 0
      fi
    elif start break $((BREAK_MINUTES * 60)); then
      announce complete "Break" "Focus session $finished of $SESSIONS done. Back in $BREAK_MINUTES minutes."
      return 0
    fi
    # The break could not start, so the timer stops here, and a round that
    # missed its long break starts over.
    ((finished < SESSIONS)) || finished=0
    status=idle phase=focus value=0
    save
    return 0
  fi

  # The break is over and the next focus phase starts. It is announced first:
  # the Do Not Disturb the phase turns on would hold the notification back.
  [[ $phase != long ]] || finished=0
  announce bell "Break over" "Focus session $((finished + 1)) of $SESSIONS starts now. $FOCUS_MINUTES minutes."
  start focus $((FOCUS_MINUTES * 60)) && return 0
  # The focus phase could not start, so the timer waits for a tap.
  status=idle phase=focus value=0
  save
}

# Draws the key for the current state with `left` of `total` seconds to go
# into $dir and sets `image` to its path. deckmaster draws a button without a
# label at 64 px on the MK.2's 72 px keys.
render() {
  local left=$1 total=$2 clock
  printf -v clock '%02d:%02d' $((left / 60)) $((left % 60))

  image="$dir/pomodoro-$status-$phase-${clock/:/-}-$finished.png"
  if [[ -e $image ]]; then
    return 0
  fi

  local color=${phase_colors[$phase]} label=${phase_labels[$phase]}
  local label_color=$color clock_color=$text_color ring_opacity=1
  case $status in
    paused) label=Paused label_color=$paused_color clock_color=$dim_color ring_opacity=0.4 ;;
    idle) label_color=$dim_color clock_color=$dim_color ;;
  esac

  # The ring empties clockwise from the top as the phase runs down.
  local progress="" arc=0
  if [[ $status != idle ]] && ((total > 0)); then
    arc=$((left * ring / total))
  fi
  if ((arc > 0)); then
    progress="<circle cx=\"32\" cy=\"32\" r=\"$radius\" fill=\"none\" stroke=\"$color\" stroke-opacity=\"$ring_opacity\" stroke-width=\"4\" stroke-linecap=\"round\" stroke-dasharray=\"$arc $ring\" transform=\"rotate(-90 32 32)\"/>"
  fi

  # One dot per focus phase in the round, lit for each one finished.
  local dots="" i fill opacity
  for ((i = 0; i < SESSIONS; i++)); do
    fill=$text_color opacity=0.25
    if ((i < finished)); then
      fill=${phase_colors[focus]} opacity=1
    fi
    dots+="<circle cx=\"$((32 - (SESSIONS - 1) * 3 + i * 6))\" cy=\"47\" r=\"2\" fill=\"$fill\" fill-opacity=\"$opacity\"/>"
  done

  mkdir --parents "$dir"
  rsvg-convert --width 64 --height 64 --output "$image.tmp" <<SVG || return
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" font-family="Roboto">
  <circle cx="32" cy="32" r="$radius" fill="none" stroke="$text_color" stroke-opacity="0.15" stroke-width="4"/>
  $progress
  <text x="32" y="23" font-size="9" fill="$label_color" text-anchor="middle">$label</text>
  <text x="32" y="38" font-size="16" font-weight="bold" fill="$clock_color" text-anchor="middle">$clock</text>
  $dots
</svg>
SVG
  mv --force "$image.tmp" "$image" || return

  # Drop the images the key showed before; deckmaster keeps its own copy.
  local old stale=()
  for old in "$dir"/pomodoro-*.png; do
    [[ $old == "$image" ]] || stale+=("$old")
  done
  ((${#stale[@]} == 0)) || rm --force -- "${stale[@]}"
}

icon() {
  load
  local total=$((phase_minutes[$phase] * 60)) left
  case $status in
    running) left=$((value > now ? value - now : 0)) ;;
    paused) left=$value ;;
    *) left=$total ;;
  esac
  render "$left" "$total" || image=""
  printf '%s\n' "$image"
}

case ${1:-} in
  icon) icon ;;
  toggle) toggle ;;
  stop) stop ;;
  elapse) elapse ;;
  *)
    echo "usage: deckmaster-pomodoro icon | toggle | stop | elapse" >&2
    exit 64
    ;;
esac
