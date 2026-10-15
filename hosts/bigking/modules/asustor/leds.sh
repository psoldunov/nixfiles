# Front panel LEDs (the asustor module's /sys/class/leds entries). A LED or
# trigger this kernel lacks is skipped with a message, not treated as an
# error, so one missing piece leaves the rest working.

leds=/sys/class/leds

# led <name> <attribute> <value>
led() {
  if ! echo "$3" 2>/dev/null >"$leds/$1/$2"; then
    echo "skipped $1/$2=$3" >&2
    return 1
  fi
}

# Disk bays: blink on disk activity. The kernel has no per-disk trigger, so
# all four blink together.
for bay in 1 2 3 4; do
  led "sata$bay:green:disk" trigger disk-activity || true
done

# LAN: lit while bond0 has a link, blinking with its traffic.
if led blue:lan trigger netdev; then
  led blue:lan device_name bond0 || true
  led blue:lan link 1 || true
  led blue:lan rx 1 || true
  led blue:lan tx 1 || true
fi

# Status: steady green once the system is up, instead of the firmware's
# blinking (the IT8625 blinks it in hardware until told to stop).
for blink in /sys/devices/platform/asustor_it87.*/hwmon/hwmon*/gpled1_blink; do
  if [ -e "$blink" ]; then
    echo 0 >"$blink" || echo "skipped $blink" >&2
  fi
done
led green:status brightness 1 || true
