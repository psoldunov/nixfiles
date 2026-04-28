import { createPoll } from "ags/time"
import GLib from "gi://GLib?version=2.0"

const time = createPoll("--:--", 1000, () =>
  GLib.DateTime.new_now_local().format("%H:%M") ?? "--:--",
)

const date = createPoll("", 1000, () =>
  GLib.DateTime.new_now_local().format("%a, %b %d") ?? "",
)

function timeProgress(t: string) {
  const [h, m] = t.split(":").map((n) => parseInt(n, 10))
  if (!Number.isFinite(h) || !Number.isFinite(m)) return -1
  return ((h * 60 + m) / 1440) * 100
}

export function Time() {
  const css = time((t) => {
    const p = timeProgress(t)
    if (p < 0) return ""
    return (
      `background-image: linear-gradient(to right,` +
      ` rgba(0,0,0,0.15) 0%,` +
      ` rgba(0,0,0,0.15) ${p}%,` +
      ` transparent ${p}%,` +
      ` transparent 100%);`
    )
  })

  return (
    <overlay class="time-overlay" passThrough>
      <box class="module-box time-module" spacing={8}>
        <icon class="time-icon" icon="time-clock-symbolic" />
        <label class="time-label" label={time} />
      </box>
      <box $type="overlay" css={css} />
    </overlay>
  )
}

export function DateBlock() {
  return (
    <box class="module-box date-module" spacing={8}>
      <icon class="date-icon" icon="date-calendar-symbolic" />
      <label class="date-label" label={date} />
    </box>
  )
}
