const hyprland = await Service.import("hyprland");

export function KeyboardIndicator() {
  const keyboard_layout = Variable("EN");
  hyprland.connect("keyboard-layout", (hyprland, keyboardname, layoutname) => {
    keyboard_layout.setValue(layoutname.trim().toUpperCase().substr(0, 2));
  });

  return Widget.Box({
    classNames: ["module-box", "keyboard-module"],
    spacing: 8,
    children: [
      Widget.Icon({
        size: 16,
        icon: "keyboard-switch-symbolic",
      }),
      Widget.Label({
        class_name: "keyboard-layout",
        label: keyboard_layout.bind(),
      }),
    ],
  });
}
