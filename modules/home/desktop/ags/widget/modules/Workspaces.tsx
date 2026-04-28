import { createBinding, For } from "ags"
import Hyprland from "gi://AstalHyprland"

const hypr = Hyprland.get_default()

export default function Workspaces() {
  const workspaces = createBinding(hypr, "workspaces")
  const focused = createBinding(hypr, "focusedWorkspace")

  return (
    <box class="workspaces" spacing={6}>
      <For
        each={workspaces((ws) =>
          ws.filter((w) => w.id >= 0).sort((a, b) => a.id - b.id),
        )}
      >
        {(w) => (
          <button
            class={focused((f) =>
              `workspace-button ${f && f.id === w.id ? "focused" : ""}`,
            )}
            onClicked={() => hypr.dispatch("workspace", `${w.id}`)}
          >
            <label label={`${w.id}`} />
          </button>
        )}
      </For>
    </box>
  )
}
