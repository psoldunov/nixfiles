import { createBinding } from "ags"
import { Astal } from "ags/gtk3"
import AstalWp from "gi://AstalWp"
import { showMenuAtPointer } from "../lib/menu"

const wp = AstalWp.get_default()
const audio = wp ? wp.audio : null

const trimName = (name: string) => name.replace(/ Analog Stereo$/, "")

export default function Microphone() {
  if (!audio) return <box />

  const mic = audio.defaultMicrophone
  const icon = createBinding(mic, "volumeIcon")
  const volume = createBinding(mic, "volume")
  const label = volume((v) => `${Math.round((v || 0) * 100)}%`)

  let self: Astal.Button

  function showDevices() {
    const items = audio!.microphones.map((m) => ({
      label: `${m.id === audio!.defaultMicrophone.id ? "󰄴" : "󰄰"} ${trimName(m.description)}`,
      onActivate: () => {
        m.set_is_default(true)
      },
    }))
    showMenuAtPointer(self, items, "audio-devices-menu")
  }

  return (
    <button
      class="microphone-button"
      $={(s) => (self = s)}
      onClicked={() => mic.set_mute(!mic.mute)}
      onScroll={(_, event) => {
        const delta = event.delta_y < 0 ? 0.05 : -0.05
        const next = Math.max(0, Math.min(1, mic.volume + delta))
        mic.set_volume(next)
      }}
      onClick={(_, event: Astal.ClickEvent) => {
        if (event.button === Astal.MouseButton.SECONDARY) {
          showDevices()
        }
      }}
    >
      <box spacing={8}>
        <icon icon={icon} />
        <label label={label} />
      </box>
    </button>
  )
}
