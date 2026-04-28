import { createState } from "ags"
import { execAsync } from "ags/process"
import { interval } from "ags/time"

const [connected, setConnected] = createState(false)

async function poll() {
  try {
    const out = await execAsync(["bash", "-c", "expressvpn status"])
    setConnected(!out.trim().endsWith("Not connected"))
  } catch {
    execAsync([
      "bash",
      "-c",
      "notify-send -u critical 'Something went wrong when trying to get VPN connection status'",
    ]).catch(() => {})
  }
}

interval(5000, poll)

export const vpnConnected = connected

export async function toggleVpn() {
  const action = connected.get() ? "disconnect" : "connect"
  try {
    await execAsync(["bash", "-c", `expressvpn ${action}`])
  } catch (err) {
    console.error("toggleVpn:", err)
  }
  poll()
}
