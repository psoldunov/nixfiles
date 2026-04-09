const systemtray = await Service.import("systemtray");

export default function SysTray() {
  const excludedItems = ["Wayland to X11 Video bridge"];

  const items = systemtray.bind("items").as((items) => {
    return items
      .filter((item) => !excludedItems.includes(item.title))
      .filter((item) => item.icon !== "image-missing")
      .map((item) => {
        return Widget.Button({
          className: "system-tray-item",
          child: Widget.Icon({ icon: item.bind("icon") }),
          on_primary_click: (_, event) => item.activate(event),
          on_secondary_click: (_, event) => {
            item.openMenu(event);
            // console.log(item, event, item.menu);
          },
          tooltip_markup: item.bind("tooltip_markup"),
        });
      });
  });

  return Widget.Box({
    className: "system-tray",
    children: items,
  });
}
