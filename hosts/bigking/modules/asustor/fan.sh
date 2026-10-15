# Case fan control. Drives pwm1 of the IT8625 Super I/O (the asustor_it87
# hwmon) from the hottest HDD (drivetemp) and the CPU package (coretemp),
# whichever asks for more. hwmon numbers change between boots, so every
# device is found by name.
#
# Set by the systemd unit: DISK_MIN/DISK_MAX and CPU_MIN/CPU_MAX (°C, the
# span over which that sensor ramps the fan from MIN_PWM to 255), MIN_PWM,
# and INTERVAL (seconds).

hwmon_named() {
  local dir
  for dir in /sys/class/hwmon/hwmon*; do
    if [ "$(cat "$dir/name")" = "$1" ]; then
      echo "$dir"
    fi
  done
}

# ramp <temp> <low> <high>: 0 at or below low, 255 at or above high.
ramp() {
  local temp=$1 low=$2 high=$3
  if [ "$temp" -le "$low" ]; then
    echo 0
  elif [ "$temp" -ge "$high" ]; then
    echo 255
  else
    echo $(((temp - low) * 255 / (high - low)))
  fi
}

chip="$(hwmon_named it8625 | head -n 1)"
if [ -z "$chip" ]; then
  echo "no it8625 hwmon device; is asustor_it87 loaded?" >&2
  exit 1
fi
cpu="$(hwmon_named coretemp | head -n 1)"

pwm="$chip/pwm1"
mode="$chip/pwm1_enable"
original_mode="$(cat "$mode")"

# On any exit, error included: full speed, then the firmware's own mode.
# systemd stops the service with SIGTERM, which has to become a normal exit
# for the EXIT trap to run.
restore() {
  echo 255 >"$pwm"
  echo "$original_mode" >"$mode"
}
trap restore EXIT
trap 'exit 0' TERM INT

# 1 = manual PWM.
echo 1 >"$mode"

while true; do
  disk=0
  for dir in $(hwmon_named drivetemp); do
    temp=$(($(cat "$dir/temp1_input") / 1000))
    if [ "$temp" -gt "$disk" ]; then
      disk=$temp
    fi
  done
  package=$(($(cat "$cpu/temp1_input") / 1000))

  want=$(ramp "$disk" "$DISK_MIN" "$DISK_MAX")
  for_cpu=$(ramp "$package" "$CPU_MIN" "$CPU_MAX")
  if [ "$for_cpu" -gt "$want" ]; then
    want=$for_cpu
  fi
  if [ "$want" -lt "$MIN_PWM" ]; then
    want=$MIN_PWM
  fi
  # No disk temperature at all means drivetemp is missing: run flat out.
  if [ "$disk" -eq 0 ]; then
    want=255
  fi

  echo "$want" >"$pwm"
  sleep "$INTERVAL"
done
