const hyprland = await Service.import("hyprland");

export default function Workspaces() {
  const activeId = hyprland.active.workspace.bind("id");
  const workspaces = hyprland.bind("workspaces").as((ws) =>
    ws
      .sort((a, b) => a.id - b.id)
      .filter(({ id }) => id >= 0)
      .map(({ id }) =>
        Widget.Button({
          on_clicked: () => hyprland.messageAsync(`dispatch workspace ${id}`),
          child: Widget.Label(`${id}`),
          class_name: activeId.as(
            (i) => `workspace-button ${i === id ? "focused" : ""}`
          ),
        })
      )
  );

  return Widget.Box({
    spacing: 6,
    children: [
      // Widget.Button({
      //   class_name: "workspace-button",
      //   on_clicked: () =>
      //     hyprland.messageAsync("dispatch togglespecialworkspace"),
      //   child: Widget.Icon("special-effects-symbolic"),
      // }),
      Widget.Box({
        class_name: "workspaces",
        spacing: 6,
        children: workspaces,
      }),
    ],
  });
}
