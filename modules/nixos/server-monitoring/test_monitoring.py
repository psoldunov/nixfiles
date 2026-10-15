"""Focused configuration invariants; run through the compute queue, no server access."""

import json
import re
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[3]

# Evaluate actual composed host options, not regexes over the Nix implementation.
EXPR = r'''
let
  f = builtins.getFlake (toString ./.);
  lib = f.inputs.nixpkgs.lib;
  select = c: {
    node = { inherit (c.services.prometheus.exporters.node) listenAddress openFirewall extraFlags; };
    unitNames = builtins.attrNames c.systemd.services;
    unitTypes = lib.mapAttrs (_: s: s.serviceConfig.Type or "simple") c.systemd.services;
    containers = lib.mapAttrs (_: s: s.serviceName) c.virtualisation.oci-containers.containers;
    ports = c.networking.firewall.allowedTCPPorts;
    firewallStart = c.networking.firewall.extraCommands;
    firewallStop = c.networking.firewall.extraStopCommands;
    sampler = c.systemd.services.server-intel-gpu-sample.serviceConfig;
    perf = c.boot.kernel.sysctl."kernel.perf_event_paranoid" or null;
  };
  t = f.nixosConfigurations.BigTasty.config;
  k = f.nixosConfigurations.BigKing.config;
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
  prometheus = { inherit (t.services.prometheus) listenAddress port retentionTime extraFlags scrapeConfigs; };
  blackbox = { inherit (t.services.prometheus.exporters.blackbox) listenAddress openFirewall; };
  vhost = { inherit (t.services.nginx.virtualHosts."dashboard.theswisscheese.com") extraConfig locations forceSSL; };
  nginxConfig = t.environment.etc."nginx/nginx.conf".source.text;
  tunnels = lib.mapAttrs (_: s: builtins.attrNames s.ingress) t.services.cloudflared.tunnels;
  bootstrap = { inherit (t.systemd.services.grafana-bootstrap) before serviceConfig script; };
  services = import ./hosts/bigtasty/modules/monitoring/services.nix;
  dns = import ./hosts/bigtasty/modules/monitoring/dns.nix;
  dashboard = import ./hosts/bigtasty/modules/monitoring/dashboard.nix {
    inherit lib;
    services = import ./hosts/bigtasty/modules/monitoring/services.nix;
    dns = import ./hosts/bigtasty/modules/monitoring/dns.nix;
  };
  homarr.volumes = t.virtualisation.oci-containers.containers.homarr.volumes;
  kuma = t.services.uptime-kuma.enable;
}
'''


class MonitoringConfigurationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        result = subprocess.run(
            ["nix", "eval", "--impure", "--json", "--expr", EXPR],
            cwd=ROOT, text=True, capture_output=True, check=False,
        )
        if result.returncode:
            raise RuntimeError(result.stderr)
        cls.c = json.loads(result.stdout)

    def test_loopback_bindings_and_nas_source_firewall(self):
        c = self.c
        self.assertEqual(c["tasty"]["node"]["listenAddress"], "127.0.0.1")
        self.assertEqual(c["king"]["node"]["listenAddress"], "10.24.24.3")
        for host in ("tasty", "king"):
            self.assertFalse(c[host]["node"]["openFirewall"])
            self.assertNotIn(9100, c[host]["ports"])
        self.assertEqual(c["prometheus"]["listenAddress"], "127.0.0.1")
        self.assertEqual(c["blackbox"]["listenAddress"], "127.0.0.1")
        self.assertFalse(c["blackbox"]["openFirewall"])
        self.assertIn("-A nixos-fw -i bond0 -s 10.24.24.2/32 -d 10.24.24.3/32 -p tcp --dport 9100 -j nixos-fw-accept", c["king"]["firewallStart"])
        self.assertIn("iptables -w -A", c["king"]["firewallStart"])
        # Rules belong to the native nixos-fw chain, disconnected on stop and
        # flushed on reload. No custom deletion hook should suppress failures.
        self.assertNotIn("9100", c["king"]["firewallStop"])
        monitoring_rules = [line for line in c["king"]["firewallStart"].splitlines() if "--dport 9100" in line]
        self.assertEqual(len(monitoring_rules), 1)
        self.assertNotIn("|| true", monitoring_rules[0])

    def test_dashboard_requires_login_and_actual_lan_peer(self):
        g = self.c["grafana"]
        s = g["settings"]
        self.assertFalse(g["openFirewall"])
        self.assertEqual(s["server"]["http_addr"], "127.0.0.1")
        self.assertEqual(s["server"]["root_url"], "https://dashboard.theswisscheese.com/")
        self.assertTrue(s["server"]["enforce_domain"])
        self.assertTrue(self.c["vhost"]["forceSSL"])
        # Inspect the native module's rendered location, not just the option's intent.
        nginx = self.c["nginxConfig"]
        server = next(block for block in nginx.split("server {")
                      if re.search(r"server_name dashboard\.theswisscheese\.com\s*;", block)
                      and "proxy_pass http://127.0.0.1:3000;" in block)
        self.assertRegex(server, r"listen [^;]*443 ssl\s*;")
        location = re.search(r"location / \{(.*?)\n\s*\}", server, re.S).group(1)
        self.assertIn("proxy_set_header Upgrade $http_upgrade;", location)
        include = re.search(r"include (/nix/store/[^;]*nginx-recommended-proxy_set_header-headers.conf);", location)
        self.assertIsNotNone(include, "Grafana's proxy location must preserve the public Host and HTTPS scheme")
        # Realize only the tiny native header snippet, not every nginx vhost dependency.
        headers_path = include.group(1)
        subprocess.run(["nix-store", "--realise", headers_path],
                       cwd=ROOT, text=True, capture_output=True, check=True)
        headers = Path(headers_path).read_text()
        for name, value in (("Host", "$host"), ("X-Forwarded-Host", "$host"),
                            ("X-Forwarded-Proto", "$scheme")):
            self.assertRegex(headers, rf"proxy_set_header\s+{name}\s+{re.escape(value)};")
        self.assertFalse(s["auth.anonymous"]["enabled"])
        self.assertFalse(s["users"]["allow_sign_up"])
        self.assertTrue(s["security"]["cookie_secure"])
        self.assertEqual(s["security"]["admin_password"], "$__file{/var/lib/grafana-bootstrap/admin-password}")
        self.assertEqual(s["security"]["secret_key"], "$__file{/var/lib/grafana-bootstrap/secret-key}")
        self.assertEqual(len(g["plugins"]), 1)  # Only the official native Prometheus datasource.
        acl = self.c["vhost"]["extraConfig"]
        self.assertIn("allow 10.24.24.0/24;", acl)
        self.assertIn("deny all;", acl)
        self.assertNotIn("real_ip", acl)
        self.assertEqual(list(self.c["vhost"]["locations"]), ["/"])
        for hosts in self.c["tunnels"].values():
            self.assertNotIn("dashboard.theswisscheese.com", hosts)
        bootstrap = self.c["bootstrap"]
        self.assertIn("grafana.service", bootstrap["before"])
        self.assertEqual(bootstrap["serviceConfig"]["StateDirectoryMode"], "0750")
        self.assertEqual(bootstrap["serviceConfig"]["User"], "root")
        self.assertEqual(bootstrap["serviceConfig"]["Group"], "grafana")
        self.assertIn('if [ ! -s /var/lib/grafana-bootstrap/"$name" ]', bootstrap["script"])
        self.assertIn("openssl rand -hex 32 >", bootstrap["script"])

    def test_inventory_matches_real_native_and_oci_unit_names(self):
        for host in ("tasty", "king"):
            c = self.c[host]
            include = next(x.split("=", 1)[1] for x in c["node"]["extraFlags"] if x.startswith("--collector.systemd.unit-include="))
            units = [x.replace("[.]", ".") for x in include[1:-1].split("|")]
            for unit in units:
                self.assertIn(unit.removesuffix(".service"), c["unitNames"], f"{host}: expected unit does not exist: {unit}")
            for name in c["containers"].values():
                self.assertIn(name + ".service", units)
            self.assertEqual(c["unitTypes"]["server-intel-gpu-sample"], "oneshot")
            self.assertEqual(c["unitTypes"]["docker-image-prune"], "oneshot")
            if host == "tasty":
                self.assertEqual(c["unitTypes"]["sharesSync"], "simple")
                self.assertEqual(c["unitTypes"]["immichSync"], "simple")
            for s in self.c["services"] if host == "tasty" else []:
                self.assertIn(s["unit"] + ".service", units)
            for unit in ("adguardhome.service", "unbound.service"):
                (self.assertIn if host == "tasty" else self.assertNotIn)(unit, units)

    def test_dns_probes_cover_every_server_and_check(self):
        scrape = self.c["prometheus"]["scrapeConfigs"]
        job = next(s for s in scrape if s["job_name"] == "dns")
        self.assertEqual(job["metrics_path"], "/probe")
        dns = self.c["dns"]
        expected = [(s["target"], s["host"], c["name"], c["module"]) for s in dns["servers"] for c in dns["checks"]]
        got = [(t["targets"][0], t["labels"]["host"], t["labels"]["check"], t["labels"]["probe_module"]) for t in job["static_configs"]]
        self.assertEqual(got, expected)
        self.assertEqual({s["target"] for s in dns["servers"]}, {"10.24.24.9:53", "10.24.24.2:53"})
        status = next(p for p in self.c["dashboard"]["panels"] if p["id"] == 16)
        self.assertEqual(len(status["targets"]), len(expected))
        for t in status["targets"]:
            self.assertIn('job="dns"', t["expr"])
            self.assertIn("or vector(-1)", t["expr"])

    def test_local_probe_targets_bound_to_catalog_and_units(self):
        scrape = self.c["prometheus"]["scrapeConfigs"]
        nodes = next(s for s in scrape if s["job_name"] == "node")["static_configs"]
        self.assertEqual([(s["targets"], s["labels"]["host"]) for s in nodes], [(["127.0.0.1:9100"], "BigTasty"), (["10.24.24.3:9100"], "BigKing")])
        web = next(s for s in scrape if s["job_name"] == "web-reachability")
        self.assertEqual(web["metrics_path"], "/probe")
        self.assertEqual(len(web["static_configs"]), len(self.c["services"]))
        for target, service in zip(web["static_configs"], self.c["services"]):
            self.assertEqual(target["targets"], [service["target"]])
            self.assertRegex(service["target"], r"^https?://127\.0\.0\.1:")
            self.assertEqual(target["labels"]["name"], service["unit"] + ".service")
            self.assertEqual(target["labels"]["url"], service["url"])
            self.assertEqual(service["module"] == "portainer_reachable", service["name"] == "portainer")
        self.assertEqual(self.c["prometheus"]["retentionTime"], "7d")
        self.assertIn("--storage.tsdb.retention.size=1GB", self.c["prometheus"]["extraFlags"])

    def test_dashboard_datasource_queries_and_honest_no_data(self):
        d = self.c["dashboard"]
        self.assertEqual(d["uid"], "home-servers")
        provision = self.c["grafana"]["provision"]
        self.assertEqual(len(provision["dashboards"]["settings"]["providers"]), 1)
        self.assertEqual(provision["datasources"]["settings"]["datasources"][0]["uid"], "server-prometheus")
        ids = [p["id"] for p in d["panels"]]
        self.assertEqual(len(ids), len(set(ids)))
        for panel in d["panels"]:
            self.assertEqual(panel["datasource"]["uid"], "server-prometheus")
            refs = [t["refId"] for t in panel.get("targets", [])]
            self.assertEqual(len(refs), len(set(refs)))
        for panel in d["panels"]:
            if panel["type"] == "stat":
                for target in panel["targets"]:
                    # Reducing a range can retain yesterday's last green sample
                    # when the current mount query is empty (exporter down).
                    self.assertTrue(target.get("instant"), panel["title"])
                    self.assertFalse(target.get("range", True), panel["title"])
        queries = "\n".join(t["expr"] for p in d["panels"] for t in p.get("targets", []))
        self.assertIn('mountpoint="/volume1"', queries)
        self.assertIn("or vector(0)", queries)
        self.assertIn("server_expected_unit_info", queries)
        self.assertIn("MISSING / NO DATA", queries)
        self.assertIn("server_expected_web_info", queries)
        self.assertIn("server_intel_gpu_last_success_timestamp_seconds < 60", queries)
        self.assertNotIn("sum(server_intel_gpu_engine", queries)
        catalog = next(p for p in d["panels"] if p["id"] == 15)["options"]["content"]
        for s in self.c["services"]:
            self.assertIn(s["url"], catalog)
        self.assertIn("7080", catalog)

    def test_capability_is_scoped_and_existing_dashboards_preserved(self):
        for host in ("tasty", "king"):
            s = self.c[host]["sampler"]
            self.assertEqual(s["AmbientCapabilities"], ["CAP_PERFMON"])
            self.assertEqual(s["CapabilityBoundingSet"], ["CAP_PERFMON"])
            self.assertEqual(s["User"], "server-monitoring")
            self.assertEqual(s["DeviceAllow"], ["char-drm rw"])
            self.assertFalse(s["PrivateUsers"])
            self.assertNotEqual(self.c[host]["perf"], -1)
        self.assertTrue(self.c["kuma"])
        self.assertIn("/RAID/apps/homarr/configs:/app/data/configs", self.c["homarr"]["volumes"])
        self.assertIn("/var/run/docker.sock:/var/run/docker.sock", self.c["homarr"]["volumes"])


if __name__ == "__main__":
    unittest.main()
