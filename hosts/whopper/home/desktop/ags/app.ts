import app from "ags/gtk3/app";
import { Astal, Gdk } from "ags/gtk3";
import style from "./style.scss";
import Bar from "./widget/Bar";

app.start({
	css: style,
	icons: `${SRC}/assets`,
	main() {
		const bars = new Map<Gdk.Monitor, Astal.Window>();

		const render = () => {
			const current = new Set(app.get_monitors());
			for (const [monitor, win] of bars) {
				if (!current.has(monitor)) {
					win.destroy();
					bars.delete(monitor);
				}
			}
			for (const monitor of current) {
				if (!bars.has(monitor)) {
					bars.set(monitor, Bar(monitor) as unknown as Astal.Window);
				}
			}
		};

		render();

		const display = Gdk.Display.get_default();
		if (display) {
			display.connect("monitor-added", render);
			display.connect("monitor-removed", render);
		}
	},
});
