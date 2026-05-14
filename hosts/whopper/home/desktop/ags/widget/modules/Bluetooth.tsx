import { createBinding } from "ags"
import { execAsync } from "ags/process"
import { Astal } from "ags/gtk3"
import AstalBluetooth from "gi://AstalBluetooth"

const bt = AstalBluetooth.get_default()

export default function Bluetooth() {
  const enabled = createBinding(bt, "isPowered")

  return (
    <box hexpand spacing={6}>
      <button
        class="bluetooth-button"
        onClicked={() => bt.toggle()}
        onClick={(_self, event: Astal.ClickEvent) => {
          if (event.button === Astal.MouseButton.SECONDARY) {
            execAsync(["bash", "-c", "blueman-manager"]).catch(() => {})
          }
        }}
      >
        <icon
          icon={enabled((on) =>
            `bluetooth-${on ? "active" : "disabled"}-symbolic`,
          )}
        />
      </button>
    </box>
  )
}
