import SystemLogo from "./modules/SystemLogo.js";
import Workspaces from "./modules/Workspaces.js";
import ClientTitle from "./modules/ClientTitle.js";
import Bluetooth from "./modules/Bluetooth.js";
import { Time, Date } from "./modules/DateTime.js";
import Weather from "./modules/Weather.js";
import Media from "./modules/Media.js";
import Speakers from "./modules/Speakers.js";
import Microphone from "./modules/Microphone.js";
import SysTray from "./modules/SysTray.js";
import IdleInhibitor from "./modules/IdleInhibitor.js";
import { KeyboardIndicator } from "./modules/Keyboard.js";
import VPN from "./modules/VPN.js";
import NetworkIndicator from "./modules/Network.js";
import SystemUsage from "./modules/SystemUsage.js";

// const revealer = Widget.Revealer({
//   revealChild: false,
//   transitionDuration: 1000,
//   transition: "slide_right",
//   child: Widget.Label("hello!"),
//   setup: (self) =>
//     self.poll(2000, () => {
//       self.reveal_child = !self.reveal_child;
//     }),
// });

function SystemPanel() {
  return Widget.Box({
    spacing: 6,
    className: "module-panel",
    children: [SystemLogo()],
  });
}

function LeftPanel() {
  return Widget.Box({
    spacing: 6,
    className: "module-panel",
    children: [Workspaces(), ClientTitle()],
  });
}

function RightPanel() {
  return Widget.Box({
    spacing: 6,
    className: "module-panel",
    children: [
      // revealer,
      Media(),
      Weather(),
      KeyboardIndicator(),
      SystemUsage(),
      NetworkIndicator(),
      VPN(),
      IdleInhibitor(),
      Bluetooth(),
      Speakers(),
      Microphone(),
      SysTray(),
      Date(),
      Time(),
    ],
  });
}

// layout of the bar
function Left() {
  return Widget.Box({
    hpack: "start",
    spacing: 8,
    children: [SystemPanel(), LeftPanel()],
  });
}

// function Center() {
//   return Widget.Box({
//     spacing: 6,
//     className: "module-panel",
//     children: [],
//   });
// }

function Right() {
  return Widget.Box({
    hpack: "end",
    spacing: 8,
    children: [RightPanel()],
  });
}

export default function Bar() {
  return Widget.Window({
    name: `bar`, // name has to be unique
    class_name: "bar",
    anchor: ["top", "left", "right"],
    exclusivity: "exclusive",
    child: Widget.CenterBox({
      class_name: "center-panel",
      start_widget: Left(),
      // center_widget: Center(),
      end_widget: Right(),
    }),
  });
}
