const routes = Variable([], {
  listen: [
    ["bash", "-c", "ip -j route show default"],
    (output) => JSON.parse(output),
  ],
});

const interfaces = Variable([], {
  poll: [10000, ["bash", "-c", "ip -j a"], (output) => JSON.parse(output)],
});

const WiredIndicator = () => {
  const getActiveInterfaceIP = (routes, interfaces) => {
    const defaultRoute = routes[0];

    if (!defaultRoute) return null;

    const activeInterface = interfaces.find(
      (i) => i.ifname === defaultRoute.dev
    );

    if (activeInterface.operstate === "DOWN") return "Disconnected";

    return activeInterface?.addr_info[0]?.local;
  };

  const getStatusIcon = (activeInterfaceIP) => {
    if (activeInterfaceIP === "Disconnected") {
      return "network-dead-symbolic";
    }

    return "network-ethernet-symbolic";
  };

  return Widget.Box({
    spacing: 8,
    tooltipText: `Wired: ${routes.value[0].dev}`,
    className: interfaces
      .bind()
      .as(
        (i) =>
          `module-box network-module ${
            getActiveInterfaceIP(routes.value, i) === "Disconnected"
              ? "network-disconnected"
              : "network-connected"
          }`
      ),
    children: [
      Widget.Icon({
        size: 16,
        icon: interfaces
          .bind()
          .as((i) => getStatusIcon(getActiveInterfaceIP(routes.value, i))),
      }),
      Widget.Label({
        label: interfaces
          .bind()
          .as((i) => getActiveInterfaceIP(routes.value, i)),
      }),
    ],
  });
};

export default function NetworkIndicator() {
  return Widget.Box({
    spacing: 8,
    children: [WiredIndicator()],
  });
}
