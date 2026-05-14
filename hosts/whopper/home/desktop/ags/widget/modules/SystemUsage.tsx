import { cpuUsage, ramUsage } from "../../services/sysusage"

const fmt = (v: number) => (v < 10 ? ` ${v}%` : `${v}%`)

export default function SystemUsage() {
  return (
    <box spacing={6}>
      <box
        class="module-box cpu-module"
        spacing={8}
        tooltipText={cpuUsage((v) => `CPU usage: ${v}%`)}
      >
        <icon icon="usage-cpu-symbolic" />
        <label label={cpuUsage(fmt)} />
      </box>
      <box
        class="module-box ram-module"
        spacing={8}
        tooltipText={ramUsage((v) => `RAM usage: ${v}%`)}
      >
        <icon icon="usage-ram-symbolic" />
        <label label={ramUsage(fmt)} />
      </box>
    </box>
  )
}
