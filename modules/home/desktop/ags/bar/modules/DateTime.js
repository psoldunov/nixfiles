const time = Variable("", {
  poll: [1000, 'date "+%H:%M"'],
});

const date = Variable("", {
  poll: [1000, 'date "+%a, %b %d"'],
});

export function Time() {
  const getTimeProgress = (time) => {
    const [hours, minutes] = time.split(":");
    return ((parseInt(hours) * 60 + parseInt(minutes)) / 1440) * 100;
  };

  return Widget.Overlay({
    visible: true,
    passThrough: true,
    class_name: "time-overlay",
    overlay: Widget.Box({
      setup: (self) =>
        self.hook(time, () => {
          self.css = `background: linear-gradient(to right, rgba(0,0,0,0.15) ${getTimeProgress(
            time.value
          )}%, rgba(0,0,0,0) ${getTimeProgress(time.value)}%);`;
        }),
      visible: true,
    }),
    child: Widget.Box({
      classNames: ["module-box", "time-module"],
      spacing: 8,
      children: [
        Widget.Icon({
          className: "time-icon",
          icon: "time-clock-symbolic",
        }),
        Widget.Label({
          className: "time-label",
          label: time.bind(),
        }),
      ],
    }),
  });
}

export function Date() {
  return Widget.Box({
    classNames: ["module-box", "date-module"],
    spacing: 8,
    children: [
      Widget.Icon({
        size: 16,
        className: "date-icon",
        icon: "date-calendar-symbolic",
      }),
      Widget.Label({
        className: "date-label",
        label: date.bind(),
      }),
    ],
  });
}
