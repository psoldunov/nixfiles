import { createState } from "ags"
import Hyprland from "gi://AstalHyprland"

const hypr = Hyprland.get_default()
const [layout, setLayout] = createState("EN")

hypr.connect("keyboard-layout", (_, _kb: string, layoutName: string) => {
  setLayout(layoutName.trim().toUpperCase().substring(0, 2))
})

export default function KeyboardIndicator() {
  return (
    <box class="module-box keyboard-module" spacing={8}>
      <icon icon="keyboard-switch-symbolic" />
      <label class="keyboard-layout" label={layout} />
    </box>
  )
}
