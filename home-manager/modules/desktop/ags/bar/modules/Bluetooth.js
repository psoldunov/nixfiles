const bluetooth = await Service.import("bluetooth");

// function BluetoothConnected() {
//   return Widget.Box({
//     spacing: 6,
//     setup: (self) =>
//       self.hook(
//         bluetooth,
//         (self) => {
//           self.children = bluetooth.connected_devices.map(
//             ({ icon_name, name }) =>
//               Widget.Box({
//                 spacing: 8,
//                 classNames: ["module-box", "bluetooth-connected-module"],
//                 children: [
//                   Widget.Icon({ size: 16, icon: icon_name + "-symbolic" }),
//                   Widget.Label(name),
//                 ],
//               }),
//           );

//           self.visible = bluetooth.connected_devices.length > 0;
//         },
//         "notify::connected-devices",
//       ),
//   });
// }

function BluetoothIndicator() {
  return Widget.Button({
    className: "bluetooth-button",
    child: Widget.Icon({
      size: 16,
      icon: bluetooth
        .bind("enabled")
        .as((on) => `bluetooth-${on ? "active" : "disabled"}-symbolic`),
    }),
    on_clicked: () => bluetooth.toggle(),
    on_secondary_click: () => {
      Utils.execAsync(["bash", "-c", "blueman-manager"]);
    },
  });
}

export default function Bluetooth() {
  return Widget.Box({
    hexpand: true,
    spacing: 6,
    children: [
      // BluetoothConnected(),
      BluetoothIndicator(),
    ],
  });
}
