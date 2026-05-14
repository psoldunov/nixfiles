import { createState } from "ags"
import { execAsync, subprocess } from "ags/process"

const [inhibited, setInhibited] = createState(false)

execAsync(["bash", "-c", "systemctl --user is-active hypridle.service"])
  .then((out) => setInhibited(out.trim() !== "active"))
  .catch(() => setInhibited(false))

subprocess(
  ["bash", "-c", "systemctl --user is-active hypridle.service"],
  (out) => setInhibited(out.trim() !== "active"),
  () => {},
)

export const idleInhibited = inhibited

export async function toggleIdleInhibitor() {
  const next = !inhibited.get()
  setInhibited(next)
  const action = next ? "stop" : "start"
  try {
    await execAsync(["bash", "-c", `systemctl --user ${action} hypridle.service`])
  } catch (err) {
    console.error("toggleIdleInhibitor:", err)
    setInhibited(!next)
  }
}
