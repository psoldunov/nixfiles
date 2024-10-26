const cpuUsage = Variable(0, {
  poll: [
    1000,
    [
      "bash",
      "-c",
      `top -bn1 | grep "Cpu(s)" | sed "s/.*, *\\([0-9.]*\\)%* id.*/\\1/" | awk '{print 100 - $1}'`,
    ],
    (output) => parseInt(output),
    (error) => {
      logError(error);
    },
  ],
});

const ramUsage = Variable(0, {
  poll: [
    1000,
    ["bash", "-c", `free | grep Mem | awk '{print $3/$2 * 100}'`],
    (output) => parseInt(output),
    (error) => {
      logError(error);
    },
  ],
});

export default function SystemUsage() {
  return Widget.Box({
    spacing: 6,
    children: [
      Widget.Box({
        spacing: 8,
        classNames: ["module-box", "cpu-module"],
        tooltipText: cpuUsage.bind().as((value) => `CPU usage: ${value}%`),
        children: [
          Widget.Icon({
            size: 16,
            icon: "usage-cpu-symbolic",
          }),
          Widget.Label({
            label: cpuUsage.bind().as((value) => {
              if (value < 10) return ` ${value}%`;
              return `${value}%`;
            }),
          }),
        ],
      }),
      Widget.Box({
        spacing: 8,
        classNames: ["module-box", "ram-module"],
        tooltipText: ramUsage.bind().as((value) => `RAM usage: ${value}%`),
        children: [
          Widget.Icon({
            size: 16,
            icon: "usage-ram-symbolic",
          }),
          Widget.Label({
            label: ramUsage.bind().as((value) => {
              if (value < 10) return ` ${value}%`;
              return `${value}%`;
            }),
          }),
        ],
      }),
    ],
  });
}
