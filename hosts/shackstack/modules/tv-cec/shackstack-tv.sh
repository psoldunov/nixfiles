# shackstack-tv on|standby: drive the Sony TV over HDMI-CEC.
#
# The CEC link is tunnelled over DisplayPort AUX by the DP->HDMI adapter
# (amdgpu exposes it as /dev/cec0). The adapter reports CEC_CAP_NEEDS_HPD:
# the kernel refuses to transmit while the TV holds hotplug low, which is the
# case in standby on some TVs and for a moment after resume while the link
# retrains. So every action first waits for a valid physical address.
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

# Claim a Playback logical address under our own name. cec-ctl allows remote
# control passthrough by default, which is what feeds TV remote presses to
# the rc-cec input device (see ./default.nix). Re-claiming is skipped when it
# is already ours, so repeated calls do not churn the bus.
claim() {
  case "$(adapter_info)" in
    *"'$osd_name'"*) ;;
    *) cec-ctl -d "$device" --playback --osd-name "$osd_name" >/dev/null || true ;;
  esac
}

# send <cec-ctl args...>: transmit, retrying for up to 5 s. The kernel claims
# the logical address in the background once the physical address is
# valid, so the first attempts after boot or resume can be refused.
send() {
  for _ in $(seq 1 10); do
    if cec-ctl -d "$device" --skip-info "$@"; then
      return 0
    fi
    sleep 0.5
  done
  echo "cec-ctl $* kept failing" >&2
  return 1
}

case "${1:-}" in
  on)
    claim
    # Up to 15 s: after resume the link takes a moment to come back.
    if ! address="$(wait_for_address 30)"; then
      echo "the TV gives no physical address (hotplug low), so CEC cannot wake it" >&2
      exit 1
    fi
    send --to "$tv" --image-view-on
    send --active-source "phys-addr=$address"
    ;;
  standby)
    claim
    # Only 2 s: no address here usually means the TV is already off, and
    # this runs on the way into suspend and power-off.
    if ! wait_for_address 4 >/dev/null; then
      echo "the TV gives no physical address (hotplug low), assuming it is already off" >&2
      exit 0
    fi
    send --to "$tv" --standby
    ;;
  *)
    echo "usage: shackstack-tv on|standby" >&2
    exit 2
    ;;
esac
