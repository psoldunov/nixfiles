import { vpnConnected, toggleVpn } from "../../services/vpn"

export default function VPN() {
  return (
    <button
      class={vpnConnected((s) => (s ? "vpn-button active" : "vpn-button"))}
      tooltipText={vpnConnected((s) => (s ? "VPN connected" : "VPN disconnected"))}
      onClicked={() => toggleVpn()}
    >
      <box spacing={8}>
        <icon icon="express-vpn-symbolic" />
        <label label="VPN" />
      </box>
    </button>
  )
}
