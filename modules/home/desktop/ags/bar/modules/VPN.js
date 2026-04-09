const status = Variable(false, {
  listen: [
    ["bash", "-c", "expressvpn status"],
    (output) => {
      if (output.endsWith("Not connected")) {
        return false;
      } else {
        return true;
      }
    },
    (error) => {
      Utils.execAsync([
        "bash",
        "-c",
        "notify-send -u critical 'Something went wrong when trying to get VPN connection status'",
      ]);
      logError(error);
    },
  ],
});

export default function VPN() {
  return Widget.Button({
    className: status
      .bind()
      .as((status) => (status ? "vpn-button active" : "vpn-button")),
    onClicked: () => {
      Utils.execAsync([
        "bash",
        "-c",
        `expressvpn ${!status.value ? "connect" : "disconnect"}`,
      ]);
      status.setValue(!status.value);
    },
    tooltipText: status
      .bind()
      .as((status) => (status ? "VPN connected" : "VPN disconnected")),
    child: Widget.Box({
      spacing: 8,
      children: [
        Widget.Icon({
          size: 16,
          icon: "express-vpn-symbolic",
        }),
        Widget.Label({
          label: "VPN",
        }),
      ],
    }),
  });
}
