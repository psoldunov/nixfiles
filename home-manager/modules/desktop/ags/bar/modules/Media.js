const mpris = await Service.import("mpris");
const hyprland = await Service.import("hyprland");

/** @param {import('types/service/mpris').MprisPlayer} player */

const focusWindow = (name) => {
  const address = hyprland.clients.find(
    (c) => c.class === (name === "spotify" ? "Spotify" : name)
  )?.address;

  if (address) {
    hyprland.sendMessage(`dispatch focuswindow address:${address}`);
  }
};

export default function Media() {
  const excludePatterns = [/spotifyd/, /firefox/, /zen/, /chromium/, /brave/];

  const Player = (player) => {
    if (excludePatterns.some((pattern) => pattern.test(player.name)))
      return null;

    const progress = Variable(0, {
      poll: [
        1000,
        () => {
          return parseInt((player.position / player.length) * 100);
        },
      ],
    });

    return Widget.Overlay({
      visible: true,
      passThrough: true,
      class_name: "media-button-overlay",
      overlay: Widget.Box({
        setup: (self) =>
          self.hook(progress, () => {
            self.css = `background: linear-gradient(to right, rgba(0,0,0,0.15) ${progress.value}%, rgba(0,0,0,0) ${progress.value}%);`;
          }),
        visible: true,
      }),
      child: Widget.Button().hook(player, (button) => {
        const {
          play_back_status,
          track_title,
          track_artists,
          name,
          playPause,
          next,
          previous,
        } = player;
        button.visible = true;
        button.spacing = 8;
        button.on_scroll_down = () => next();
        button.on_scroll_up = () => previous();
        button.onClicked = () => playPause();
        button.on_secondary_click = () => {
          focusWindow(name);
        };
        button.class_names = ["media-button", name];
        button.child = Widget.Box({
          spacing: 8,
          children: [
            Widget.Icon({
              size: 16,
              icon:
                play_back_status === "Playing"
                  ? "media-playback-start-symbolic"
                  : play_back_status === "Stopped"
                  ? "media-playback-stop-symbolic"
                  : "media-playback-pause-symbolic",
            }),
            Widget.Label({
              label:
                play_back_status !== "Stopped"
                  ? `${track_title} - ${track_artists.join(", ")}`
                  : "Stopped",
            }),
          ],
        });
      }),
    });
  };

  return Widget.Box({
    visible: mpris.bind("players").as((p) => {
      return p.map(Player).filter((p) => p !== null).length > 0;
    }),
    noShowAll: true,
    name: "media-widget",
    spacing: 8,
    children: mpris.bind("players").as((p) => {
      return p.map(Player).filter((p) => p !== null);
    }),
  });
}
