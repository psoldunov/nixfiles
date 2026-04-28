import { createBinding, For } from "ags"
import { Astal } from "ags/gtk3"
import AstalTray from "gi://AstalTray"
import { showModelMenuAtWidget } from "../lib/menu"

const tray = AstalTray.get_default()
const EXCLUDED = new Set(["Wayland to X11 Video bridge"])

function isUsable(i: AstalTray.TrayItem) {
  const name = i.iconName
  if (!name || name === "image-missing") return false
  if (EXCLUDED.has(i.title)) return false
  return true
}

export default function SysTray() {
  const items = createBinding(tray, "items")

  return (
    <box class="system-tray">
      <For each={items((arr) => arr.filter(isUsable))}>
        {(item) => {
          const iconName = createBinding(item, "iconName")
          let self: Astal.Button
          return (
            <button
              class="system-tray-item"
              $={(s) => (self = s)}
              tooltipMarkup={createBinding(item, "tooltipMarkup")((m) => m ?? "")}
              onClicked={() => item.activate(0, 0)}
              onClick={(_, event: Astal.ClickEvent) => {
                if (event.button === Astal.MouseButton.SECONDARY) {
                  item.about_to_show()
                  showModelMenuAtWidget(self, item.menuModel, item.actionGroup)
                }
              }}
            >
              <icon icon={iconName((n) => n || "image-missing")} />
            </button>
          )
        }}
      </For>
    </box>
  )
}
