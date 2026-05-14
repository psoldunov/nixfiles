import app from "ags/gtk3/app"
import { onCleanup } from "ags"
import { Astal, Gtk, Gdk } from "ags/gtk3"

import SystemLogo from "./modules/SystemLogo"
import Workspaces from "./modules/Workspaces"
import ClientTitle from "./modules/ClientTitle"
import Bluetooth from "./modules/Bluetooth"
import { Time, DateBlock } from "./modules/DateTime"
import Weather from "./modules/Weather"
import Media from "./modules/Media"
import Speakers from "./modules/Speakers"
import Microphone from "./modules/Microphone"
import SysTray from "./modules/SysTray"
import IdleInhibitor from "./modules/IdleInhibitor"
import KeyboardIndicator from "./modules/Keyboard"
import VPN from "./modules/VPN"
import NetworkIndicator from "./modules/Network"
import SystemUsage from "./modules/SystemUsage"

const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

function SystemPanel() {
  return (
    <box class="module-panel" spacing={6}>
      <SystemLogo />
    </box>
  )
}

function LeftPanel() {
  return (
    <box class="module-panel" spacing={6}>
      <Workspaces />
      <ClientTitle />
    </box>
  )
}

function RightPanel() {
  return (
    <box class="module-panel" spacing={6}>
      <Media />
      <Weather />
      <KeyboardIndicator />
      <SystemUsage />
      <NetworkIndicator />
      <VPN />
      <IdleInhibitor />
      <Bluetooth />
      <Speakers />
      <Microphone />
      <SysTray />
      <DateBlock />
      <Time />
    </box>
  )
}

export default function Bar(gdkmonitor: Gdk.Monitor) {
  let win: Astal.Window

  onCleanup(() => {
    win?.destroy()
  })

  return (
    <window
      $={(self) => (win = self)}
      name="bar"
      class="bar"
      application={app}
      gdkmonitor={gdkmonitor}
      anchor={TOP | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
    >
      <centerbox class="center-panel">
        <box $type="start" halign={Gtk.Align.START} spacing={8}>
          <SystemPanel />
          <LeftPanel />
        </box>
        <box $type="end" halign={Gtk.Align.END} spacing={8}>
          <RightPanel />
        </box>
      </centerbox>
    </window>
  )
}
