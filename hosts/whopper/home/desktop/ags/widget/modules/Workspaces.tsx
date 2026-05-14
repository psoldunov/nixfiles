import { createBinding, createComputed, For } from "ags"
import Hyprland from "gi://AstalHyprland"

const hypr = Hyprland.get_default()

export default function Workspaces() {
  const workspaces = createBinding(hypr, "workspaces")
  const focusedId = createBinding(hypr, "focusedWorkspace", "id")

  return (
    <box class="workspaces" spacing={6}>
      <For
        each={workspaces((ws) =>
          ws.filter((w) => w.id > 0).sort((a, b) => a.id - b.id),
        )}
      >
        {(w) => {
          const wsId = createBinding(w, "id")
          return (
            <button
              class={createComputed(
                [focusedId, wsId],
                (f, id) => `workspace-button ${f === id ? "focused" : ""}`,
              )}
              onClicked={() => w.focus()}
            >
              <label label={wsId((id) => `${id}`)} />
            </button>
          )
        }}
      </For>
    </box>
  )
}
