import { createPoll } from "ags/time"

const cpuCmd = `top -bn1 | grep "Cpu(s)" | sed "s/.*, *\\([0-9.]*\\)%* id.*/\\1/" | awk '{print 100 - $1}'`
const ramCmd = `free | grep Mem | awk '{print $3/$2 * 100}'`

export const cpuUsage = createPoll(0, 1000, ["bash", "-c", cpuCmd], (out) => {
  const v = parseInt(out, 10)
  return Number.isFinite(v) ? v : 0
})

export const ramUsage = createPoll(0, 1000, ["bash", "-c", ramCmd], (out) => {
  const v = parseInt(out, 10)
  return Number.isFinite(v) ? v : 0
})
