import { createComputed } from "ags"
import { routes, interfaces } from "../../services/network"

function activeIp(rs: ReturnType<typeof routes.get>, ifs: ReturnType<typeof interfaces.get>) {
  const def = rs[0]
  if (!def) return null
  const iface = ifs.find((i) => i.ifname === def.dev)
  if (!iface) return null
  if (iface.operstate === "DOWN") return "Disconnected"
  return iface.addr_info[0]?.local ?? null
}

function statusIcon(ip: string | null) {
  return ip === "Disconnected" || ip === null
    ? "network-dead-symbolic"
    : "network-ethernet-symbolic"
}

function WiredIndicator() {
  const ip = createComputed([routes, interfaces], activeIp)
  const dev = routes((rs) => (rs[0]?.dev ?? "—"))

  return (
    <box
      class={ip((v) =>
        `module-box network-module ${v === "Disconnected" ? "network-disconnected" : "network-connected"}`,
      )}
      spacing={8}
      tooltipText={dev((d) => `Wired: ${d}`)}
    >
      <icon icon={ip(statusIcon)} />
      <label label={ip((v) => v ?? "")} />
    </box>
  )
}

export default function NetworkIndicator() {
  return (
    <box spacing={8}>
      <WiredIndicator />
    </box>
  )
}
