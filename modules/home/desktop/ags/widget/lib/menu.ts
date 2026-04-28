import { Gdk, Gtk } from "ags/gtk3"
import Gio from "gi://Gio?version=2.0"

export type MenuItemSpec = {
  label: string
  onActivate: () => void
}

export function showMenuAtPointer(
  widget: Gtk.Widget,
  items: MenuItemSpec[],
  cssClass?: string,
) {
  const menu = new Gtk.Menu()
  if (cssClass) menu.get_style_context().add_class(cssClass)

  for (const item of items) {
    const mi = new Gtk.MenuItem({ label: item.label })
    mi.connect("activate", () => item.onActivate())
    mi.show()
    menu.append(mi)
  }

  menu.attach_to_widget(widget, null)
  menu.popup_at_pointer(null)
}

export function showModelMenuAtWidget(
  widget: Gtk.Widget,
  model: Gio.MenuModel | null,
  actionGroup: Gio.ActionGroup | null,
  prefix = "dbusmenu",
) {
  if (!model) return
  const menu = Gtk.Menu.new_from_model(model) as Gtk.Menu
  if (actionGroup) menu.insert_action_group(prefix, actionGroup)
  menu.attach_to_widget(widget, null)
  menu.popup_at_widget(widget, Gdk.Gravity.SOUTH_WEST, Gdk.Gravity.NORTH_WEST, null)
}
