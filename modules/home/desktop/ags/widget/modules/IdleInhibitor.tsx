import { idleInhibited, toggleIdleInhibitor } from "../../services/idle"

export default function IdleInhibitor() {
  return (
    <button
      class={idleInhibited((on) => `idle-inhibitor${on ? " active" : ""}`)}
      onClicked={() => toggleIdleInhibitor()}
    >
      <icon icon={idleInhibited((on) => (on ? "eye-symbolic" : "eye-slash-symbolic"))} />
    </button>
  )
}
