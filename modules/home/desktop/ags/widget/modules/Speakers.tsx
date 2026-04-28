import { createBinding } from "ags"
import { execAsync } from "ags/process"
import { Astal } from "ags/gtk3"
import AstalWp from "gi://AstalWp"
import { showMenuAtPointer } from "../lib/menu"

const wp = AstalWp.get_default()
const audio = wp ? wp.audio : null

function trimName(name: string) {
  return name
    .replace(/ Analog Stereo$/, "")
    .replace(/ Digital Stereo \(IEC958\)$/, "")
}

export default function Speakers() {
  if (!audio) return <box />

  const speaker = audio.defaultSpeaker
  const icon = createBinding(speaker, "volumeIcon")
  const volume = createBinding(speaker, "volume")
  const label = volume((v) => `${Math.round((v || 0) * 100)}%`)

  let self: Astal.Button

  function showDevices() {
    const items = audio!.speakers.map((sp) => ({
      label: `${sp.id === audio!.defaultSpeaker.id ? "󰄴" : "󰄰"} ${trimName(sp.description)}`,
      onActivate: () => {
        sp.set_is_default(true)
      },
    }))
    showMenuAtPointer(self, items, "audio-devices-menu")
  }

  return (
    <button
      class="volume-button"
      $={(s) => (self = s)}
      onClicked={() => speaker.set_mute(!speaker.mute)}
      onScroll={(_, event) => {
        const delta = event.delta_y < 0 ? 0.05 : -0.05
        const next = Math.max(0, Math.min(1, speaker.volume + delta))
        speaker.set_volume(next)
      }}
      onClick={(_, event: Astal.ClickEvent) => {
        if (event.button === Astal.MouseButton.MIDDLE) {
          execAsync(["bash", "-c", "pavucontrol"]).catch(() => {})
        } else if (event.button === Astal.MouseButton.SECONDARY) {
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
