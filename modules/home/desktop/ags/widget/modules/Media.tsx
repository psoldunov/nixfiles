import { createBinding, createComputed, For } from "ags"
import { Astal } from "ags/gtk3"
import Mpris from "gi://AstalMpris"
import Hyprland from "gi://AstalHyprland"

const mpris = Mpris.get_default()
const hypr = Hyprland.get_default()

const EXCLUDE = [/spotifyd/, /firefox/, /zen/, /chromium/, /brave/]

function focusEntry(entry: string) {
  const cls = entry === "spotify" ? "Spotify" : entry
  const client = hypr.clients.find((c) => c.class === cls)
  if (client) hypr.dispatch("focuswindow", `address:${client.address}`)
}

function filter(players: Mpris.Player[]) {
  return players.filter(
    (p) => !EXCLUDE.some((re) => re.test(p.busName) || re.test(p.entry || "")),
  )
}

function Player({ player }: { player: Mpris.Player }) {
  const status = createBinding(player, "playbackStatus")
  const title = createBinding(player, "title")
  const artist = createBinding(player, "artist")
  const position = createBinding(player, "position")
  const length = createBinding(player, "length")

  const progress = createComputed([position, length], (p, l) =>
    l > 0 ? Math.round((p / l) * 100) : 0,
  )

  const icon = status((s) =>
    s === Mpris.PlaybackStatus.PLAYING
      ? "media-playback-start-symbolic"
      : s === Mpris.PlaybackStatus.STOPPED
        ? "media-playback-stop-symbolic"
        : "media-playback-pause-symbolic",
  )

  const text = createComputed([status, title, artist], (s, t, a) =>
    s === Mpris.PlaybackStatus.STOPPED ? "Stopped" : `${t || ""} - ${a || ""}`,
  )

  const css = progress(
    (p) =>
      `background-image: linear-gradient(to right, rgba(0,0,0,0.15) ${p}%, rgba(0,0,0,0) ${p}%);`,
  )

  return (
    <button
      class={`media-button ${player.entry || ""}`}
      css={css}
      onClicked={() => player.play_pause()}
      onClick={(_, event: Astal.ClickEvent) => {
        if (event.button === Astal.MouseButton.SECONDARY) {
          focusEntry(player.entry || "")
        }
      }}
      onScroll={(_, event) => {
        if (event.delta_y < 0) player.previous()
        else player.next()
      }}
    >
      <box spacing={8}>
        <icon icon={icon} />
        <label label={text} />
      </box>
    </button>
  )
}

export default function Media() {
  const players = createBinding(mpris, "players")
  const visible = players((p) => filter(p).length > 0)

  return (
    <box spacing={8} visible={visible}>
      <For each={players(filter)}>
        {(player) => <Player player={player} />}
      </For>
    </box>
  )
}
