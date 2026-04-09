const hyprland = await Service.import("hyprland");

export default function ClientTitle() {
  const truncate = (text, length) => {
    return text.length > length ? text.substring(0, length) + "..." : text;
  };

  return Widget.Box({
    spacing: 6,
    visible: hyprland.active.client.bind("title"),
    classNames: ["module-box", "client-title-module"],
    children: [
      Widget.Label({
        class_name: "client-title",
        label: hyprland.active.client
          .bind("title")
          .as((title) => truncate(title, 56)),
      }),
    ],
  });
}
