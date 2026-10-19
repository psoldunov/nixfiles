# shackstack-pad-wake: after a resume, finish connecting the Bluetooth
# controller that woke ShackStack.
#
# A controller that wakes the system connects while it is still asleep. On
# resume the AX211 hands the kernel two things over separate USB endpoints:
# the event announcing the connection, and the controller's first packet,
# its request to open the HID channel. When the packet arrives first, the
# kernel drops it ("ACL packet for unknown connection handle" in the kernel
# log). The link then sits idle with no HID channel, the kernel closes it
# after 2 s, and the controller switches itself off. Seen on two of three
# resumes on 2026-10-19.
#
# So for a few seconds after resume, a paired, wake-allowed device whose link
# is up but has no HID device yet gets a connect from this side, which makes
# bluetoothd open the HID channels itself. A controller whose own request got
# through has its HID device within a tenth of a second and is left alone.
#
# Runs under writeShellApplication's errexit/nounset/pipefail.

# Poll every 0.2 s for 8 s, and act once a link has gone 0.6 s without a HID
# device: early enough to beat the kernel's 2 s idle disconnect.
polls=40
patience=3

# Paired devices allowed to wake the system, one address per line.
wake_devices() {
  local mac
  for mac in $(bluetoothctl devices Paired | awk '$1 == "Device" {print $2}'); do
    if [[ "$(bluetoothctl info "$mac")" == *"WakeAllowed: yes"* ]]; then
      echo "$mac"
    fi
  done
}

link_up() {
  [[ "$(bluetoothctl info "$1")" == *"Connected: yes"* ]]
}

# has_hid <address>: a HID device exists for it. bluetoothd creates them
# through uhid with the address, in lower case, as HID_UNIQ.
has_hid() {
  local want="HID_UNIQ=${1,,}" uevent
  for uevent in /sys/bus/hid/devices/*/uevent; do
    if [ -e "$uevent" ] && grep -qxF "$want" "$uevent"; then
      return 0
    fi
  done
  return 1
}

# connect <address>: open the HID channels from this side and report.
connect() {
  echo "$1: link up but no HID device, connecting from ShackStack"
  bluetoothctl --timeout 10 connect "$1" || true
  if has_hid "$1"; then
    echo "$1: HID device is up"
  else
    echo "$1: still no HID device; switch the controller on again" >&2
  fi
}

mapfile -t devices < <(wake_devices)
if [ "${#devices[@]}" -eq 0 ]; then
  echo "no paired device may wake the system"
  exit 0
fi

declare -A idle=() handled=()
for _ in $(seq 1 "$polls"); do
  for mac in "${devices[@]}"; do
    if [ -n "${handled[$mac]:-}" ]; then
      continue
    fi
    if link_up "$mac" && ! has_hid "$mac"; then
      idle[$mac]=$((${idle[$mac]:-0} + 1))
    else
      idle[$mac]=0
    fi
    if [ "${idle[$mac]}" -ge "$patience" ]; then
      handled[$mac]=1
      connect "$mac"
    fi
  done
  sleep 0.2
done
