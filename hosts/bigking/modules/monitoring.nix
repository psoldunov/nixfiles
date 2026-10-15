{...}: {
  services.prometheus.exporters.node.listenAddress = "10.24.24.3";
  # No global 9100 opening. Only BigTasty may scrape the NAS, on the LAN bond.
  # NixOS disconnects nixos-fw on stop and flushes it on start/reload, so this
  # chain-owned rule needs no custom deletion hook (or suppressed failures).
  networking.firewall.extraCommands = ''
    iptables -w -A nixos-fw -i bond0 -s 10.24.24.2/32 -d 10.24.24.3/32 -p tcp --dport 9100 -j nixos-fw-accept
  '';
}
