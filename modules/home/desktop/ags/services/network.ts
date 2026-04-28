import { createPoll } from "ags/time"

type Route = { dev: string; dst?: string; gateway?: string }
type Interface = {
  ifname: string
  operstate: string
  addr_info: { local: string }[]
}

export const routes = createPoll<Route[]>(
  [],
  10000,
  ["bash", "-c", "ip -j route show default"],
  (out) => {
    try {
      return JSON.parse(out) as Route[]
    } catch {
      return []
    }
  },
)

export const interfaces = createPoll<Interface[]>(
  [],
  10000,
  ["bash", "-c", "ip -j a"],
  (out) => {
    try {
      return JSON.parse(out) as Interface[]
    } catch {
      return []
    }
  },
)
