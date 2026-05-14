import { execAsync } from "ags/process"
import { Astal } from "ags/gtk3"
import { showMenuAtPointer } from "../lib/menu"

const POWER_ITEMS = [
  { label: "Shutdown", cmd: "systemctl poweroff" },
  { label: "Reboot", cmd: "systemctl reboot" },
  { label: "Suspend", cmd: "systemctl suspend" },
  { label: "Lock Session", cmd: "loginctl lock-session" },
]

export default function SystemLogo() {
  let self: Astal.Button

  return (
    <button
      class="system-logo"
      $={(s) => (self = s)}
      onClicked={() => execAsync(["bash", "-c", "rofi -show drun"]).catch(() => {})}
      onClick={(_, event: Astal.ClickEvent) => {
        if (event.button === Astal.MouseButton.MIDDLE) {
          execAsync(["bash", "-c", "kitty -e --hold fastfetch"]).catch(() => {})
        } else if (event.button === Astal.MouseButton.SECONDARY) {
          showMenuAtPointer(
            self,
            POWER_ITEMS.map(({ label, cmd }) => ({
              label,
              onActivate: () => {
                execAsync(["bash", "-c", cmd]).catch(() => {})
              },
            })),
            "power-menu",
          )
        }
      }}
    >
      <icon icon="nixos" />
    </button>
  )
}
