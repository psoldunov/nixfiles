const powerMenu = Widget.Menu({
  class_name: "power-menu",
  children: [
    Widget.MenuItem({
      child: Widget.Label({
        label: "Shutdown",
        hpack: "start",
      }),
      onActivate: () => {
        Utils.execAsync(["bash", "-c", "systemctl poweroff"]);
      },
    }),
    Widget.MenuItem({
      child: Widget.Label({
        label: "Reboot",
        hpack: "start",
      }),
      onActivate: () => {
        Utils.execAsync(["bash", "-c", "systemctl reboot"]);
      },
    }),
    Widget.MenuItem({
      child: Widget.Label({
        label: "Suspend",
        hpack: "start",
      }),
      onActivate: () => {
        Utils.execAsync(["bash", "-c", "systemctl suspend"]);
      },
    }),
    Widget.MenuItem({
      child: Widget.Label({
        label: "Lock Session",
        hpack: "start",
      }),
      onActivate: () => {
        Utils.execAsync(["bash", "-c", "loginctl lock-session"]);
      },
    }),
  ],
});

export default function SystemLogo() {
  return Widget.Button({
    class_name: "system-logo",
    child: Widget.Icon({
      icon: "nixos",
      size: 22,
    }),
    on_primary_click: () => {
      Utils.execAsync(["bash", "-c", "rofi -show drun"]);
    },
    on_middle_click: () => {
      Utils.execAsync([
        "bash",
        "-c",
        "ghostty --wait-after-command=true -e fastfetch",
      ]);
    },
    on_secondary_click: (_, event) => {
      powerMenu.popup_at_pointer(event);
    },
  });
}
