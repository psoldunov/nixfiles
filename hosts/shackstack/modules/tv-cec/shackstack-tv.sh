# shackstack-tv on|standby: drive the Sony TV over HDMI-CEC.
#
# The CEC link is tunnelled over DisplayPort AUX by the DP->HDMI adapter
# (amdgpu exposes it as /dev/cec0). Three quirks shape this script:
#
# - The adapter reports CEC_CAP_NEEDS_HPD: the kernel refuses to transmit
#   while the TV holds hotplug low, which is the case in standby on some TVs
#   and for a moment after resume while the link retrains. So every action
#   first waits for a valid physical address.
# - The adapter forgets that CEC tunnelling is on when it loses power in
#   suspend. The kernel keeps /dev/cec0, its physical address and our logical
#   address across the suspend, and only switches tunnelling on when the
#   logical address is claimed. So after a resume every message goes nowhere
#   and the TV acknowledges none of them, until something claims again.
#   Every action therefore clears the logical address and claims it afresh.
# - cec-ctl exits 0 even when the TV did not acknowledge a message, so send()
#   reads the transmit status itself and retries.
#
# Runs under writeShellApplication's errexit/nounset/pipefail.

osd_name="ShackStack"
tv=0

device=""
for candidate in /dev/cec*; do
  if [ -e "$candidate" ]; then
    device="$candidate"
    break
  fi
done
if [ -z "$device" ]; then
  echo "no CEC device: the adapter's CEC tunnel is not registered" >&2
  exit 1
fi

# The adapter's state as cec-ctl prints it; empty if it cannot be read.
adapter_info() {
  cec-ctl -d "$device" 2>/dev/null || true
}

# wait_for_address <tries>: prints the physical address once it is valid,
# polling every 0.5 s; fails after <tries> polls.
wait_for_address() {
  local address
  for _ in $(seq 1 "$1"); do
    address="$(adapter_info | awk '/Physical Address/ {print $4; exit}')"
    if [ -n "$address" ] && [ "$address" != "f.f.f.f" ]; then
      echo "$address"
      return 0
    fi
    sleep 0.5
  done
  return 1
}

# Drop our logical address and claim a Playback one again under our own
# name. Claiming is what switches the adapter's CEC tunnel back on (see the
# top). cec-ctl allows remote control passthrough by default, which is what
# feeds TV remote presses to the rc-cec input device (see ./default.nix).
reclaim() {
  cec-ctl -d "$device" --clear >/dev/null 2>&1 || true
  cec-ctl -d "$device" --playback --osd-name "$osd_name" >/dev/null 2>&1 || true
}

# delivered <cec-ctl output>: fails if the transmit did not get through. A
# delivered message prints no status line; a failed one prints one such as
# "Tx, Not Acknowledged (1), Max Retries". A message sent before the claim
# has finished goes out from Unregistered, which the TV ignores.
delivered() {
  awk '/Tx, / && !/Tx, OK/ {failed = 1} /from Unregistered/ {failed = 1} END {exit failed}' <<<"$1"
}

# send <tries> <cec-ctl args...>: transmit until the TV acknowledges it,
# claiming afresh before each retry. A try takes about a second.
send() {
  local tries="$1" out=""
  shift
  for try in $(seq 1 "$tries"); do
    if out="$(cec-ctl -d "$device" --skip-info "$@" 2>&1)" && delivered "$out"; then
      printf '%s\n' "$out"
      return 0
    fi
    echo "try $try of $tries: cec-ctl $* was not delivered" >&2
    reclaim
    sleep 0.5
  done
  printf '%s\n' "$out" >&2
  echo "cec-ctl $* kept failing" >&2
  return 1
}

case "${1:-}" in
  on)
    # Up to 15 s: after resume the link takes a moment to come back.
    if ! address="$(wait_for_address 30)"; then
      echo "the TV gives no physical address (hotplug low), so CEC cannot wake it" >&2
      exit 1
    fi
    reclaim
    send 10 --to "$tv" --image-view-on
    send 10 --active-source "phys-addr=$address"
    ;;
  standby)
    # Only 2 s: no address here usually means the TV is already off, and
    # this runs on the way into suspend and power-off.
    if ! wait_for_address 4 >/dev/null; then
      echo "the TV gives no physical address (hotplug low), assuming it is already off" >&2
      exit 0
    fi
    reclaim
    send 4 --to "$tv" --standby
    ;;
  *)
    echo "usage: shackstack-tv on|standby" >&2
    exit 2
    ;;
esac
