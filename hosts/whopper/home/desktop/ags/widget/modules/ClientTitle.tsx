import { createBinding } from "ags"
import Hyprland from "gi://AstalHyprland"

const hypr = Hyprland.get_default()

const truncate = (text: string, length: number) =>
  text.length > length ? `${text.substring(0, length)}...` : text

export default function ClientTitle() {
  const focused = createBinding(hypr, "focusedClient")
  const title = focused((c) => (c ? c.title : ""))

  return (
    <box
      class="module-box client-title-module"
      spacing={6}
      visible={title((t) => Boolean(t))}
    >
      <label class="client-title" label={title((t) => truncate(t || "", 56))} />
    </box>
  )
}
