# Composed BigTasty/BigKing monitoring options, as test_monitoring.py reads them.
# `flake` is the flake's outputs (`self`, or `builtins.getFlake` standalone).
{flake}: let
  lib = flake.inputs.nixpkgs.lib;
  select = c: {
    node = {inherit (c.services.prometheus.exporters.node) listenAddress openFirewall extraFlags;};
    unitNames = builtins.attrNames c.systemd.services;
    unitTypes = lib.mapAttrs (_: s: s.serviceConfig.Type or "simple") c.systemd.services;
    containers = lib.mapAttrs (_: s: s.serviceName) c.virtualisation.oci-containers.containers;
    ports = c.networking.firewall.allowedTCPPorts;
    firewallStart = c.networking.firewall.extraCommands;
    firewallStop = c.networking.firewall.extraStopCommands;
    sampler = c.systemd.services.server-intel-gpu-sample.serviceConfig;
    perf = c.boot.kernel.sysctl."kernel.perf_event_paranoid" or null;
  };
  t = flake.nixosConfigurations.BigTasty.config;
  k = flake.nixosConfigurations.BigKing.config;
  monitoring = "${flake}/hosts/bigtasty/modules/monitoring";
  services = import "${monitoring}/services.nix";
  dns = import "${monitoring}/dns.nix";
  nginxConfig = t.environment.etc."nginx/nginx.conf".source.text;
  # The tiny proxy header snippet the vhost includes, read here so the test
  # needs no nix-store call. `builtins.match` drops string context, so it is put
  # back before the read, which realises only that one derivation.
  headersPattern = ".*include (/nix/store/[^;]*nginx-recommended-proxy_set_header-headers.conf);.*";
  headersPath = builtins.head (builtins.match headersPattern nginxConfig);
  headersDrv = builtins.head (builtins.filter (d: builtins.match ".*nginx-recommended-proxy_set_header-headers.conf.drv" d != null) (builtins.attrNames (builtins.getContext nginxConfig)));
in {
  tasty = select t;
  king = select k;
  grafana = {
    inherit (t.services.grafana) settings openFirewall;
    provision = {
      datasources.settings = t.services.grafana.provision.datasources.settings;
      dashboards.settings = t.services.grafana.provision.dashboards.settings;
    };
    plugins = map toString t.services.grafana.declarativePlugins;
  };
  prometheus = {inherit (t.services.prometheus) listenAddress port retentionTime extraFlags scrapeConfigs;};
  blackbox = {inherit (t.services.prometheus.exporters.blackbox) listenAddress openFirewall;};
  vhost = {inherit (t.services.nginx.virtualHosts."dashboard.theswisscheese.com") extraConfig locations forceSSL;};
  inherit nginxConfig;
  tunnels = lib.mapAttrs (_: s: builtins.attrNames s.ingress) t.services.cloudflared.tunnels;
  bootstrap = {inherit (t.systemd.services.grafana-bootstrap) before serviceConfig script;};
  inherit services dns;
  dashboard = import "${monitoring}/dashboard.nix" {inherit lib services dns;};
  homarr.volumes = t.virtualisation.oci-containers.containers.homarr.volumes;
  kuma = t.services.uptime-kuma.enable;
  proxyHeaders = builtins.readFile (builtins.appendContext headersPath {${headersDrv}.outputs = ["out"];});
}
