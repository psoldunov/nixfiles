{
  config,
  lib,
  pkgs,
  ...
}: let
  services = import ./services.nix;
  dns = import ./dns.nix;
  dashboard = import ./dashboard.nix {inherit lib services dns;};
  dashboardDir = pkgs.writeTextDir "home.json" (builtins.toJSON dashboard);
  secretDir = "/var/lib/grafana-bootstrap";
  http = {
    prober = "http";
    timeout = "5s";
    http = {
      method = "GET";
      follow_redirects = false;
      preferred_ip_protocol = "ip4";
      # Authentication/redirects prove an HTTP server is responding, not that an app is healthy.
      valid_status_codes = [
        200
        201
        202
        204
        206
        301
        302
        303
        307
        308
        401
        403
        409
      ];
    };
  };
  # A non-empty answer of the right type, so an empty NOERROR fails too.
  dnsProbe = name: answer: {
    prober = "dns";
    timeout = "5s";
    dns = {
      query_name = name;
      query_type = "A";
      transport_protocol = "udp";
      preferred_ip_protocol = "ip4";
      valid_rcodes = ["NOERROR"];
      validate_answer_rrs.fail_if_none_matches_regexp = [answer];
    };
  };
  probeRelabel = [
    {
      source_labels = ["__address__"];
      target_label = "__param_target";
    }
    {
      source_labels = ["probe_module"];
      target_label = "__param_module";
    }
    {
      source_labels = ["__param_target"];
      target_label = "instance";
    }
    {
      target_label = "__address__";
      replacement = "127.0.0.1:9115";
    }
  ];
  webInventory = pkgs.writeText "server-web-inventory.prom" (
    lib.concatMapStrings (s: ''
      server_expected_web_info{service="${s.name}",name="${s.unit}.service",url="${s.url}"} 1
    '')
    services
  );
in {
  boot.kernelModules = ["drivetemp"];

  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9090;
    retentionTime = "7d";
    extraFlags = ["--storage.tsdb.retention.size=1GB"];
    globalConfig = {
      scrape_interval = "15s";
      evaluation_interval = "15s";
    };
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = ["127.0.0.1:9100"];
            labels.host = "BigTasty";
          }
          {
            targets = ["10.24.24.3:9100"];
            labels.host = "BigKing";
          }
        ];
      }
      {
        job_name = "web-reachability";
        metrics_path = "/probe";
        scrape_timeout = "8s";
        static_configs =
          map (s: {
            targets = [s.target];
            labels = {
              host = "BigTasty";
              service = s.name;
              name = "${s.unit}.service";
              url = s.url;
              probe_module = s.module;
            };
          })
          services;
        relabel_configs = probeRelabel;
      }
      {
        job_name = "dns";
        metrics_path = "/probe";
        scrape_timeout = "8s";
        static_configs = lib.concatMap (s:
          map (c: {
            targets = [s.target];
            labels = {
              inherit (s) host role;
              check = c.name;
              probe_module = c.module;
            };
          })
          dns.checks)
        dns.servers;
        relabel_configs = probeRelabel;
      }
    ];
    exporters.blackbox = {
      enable = true;
      listenAddress = "127.0.0.1";
      openFirewall = false;
      configFile = (pkgs.formats.yaml {}).generate "blackbox-monitoring.yml" {
        modules = {
          http_reachable = http;
          # Only Portainer's existing self-signed loopback endpoint gets this exception.
          portainer_reachable =
            http
            // {
              http =
                http.http
                // {
                  tls_config.insecure_skip_verify = true;
                };
            };
          dns_resolves = dnsProbe "example.org" "\\sIN\\s+A\\s+[0-9.]+$";
          dns_rewrite = dnsProbe "portainer.theswisscheese.com" "\\sIN\\s+A\\s+10\\.24\\.24\\.2$";
        };
      };
    };
  };
  # Blackbox performs HTTP and DNS only; the native module's ICMP capability is unnecessary.
  systemd.services.prometheus-blackbox-exporter.serviceConfig.AmbientCapabilities = lib.mkForce [];
  systemd.services.server-monitoring-inventory.script = lib.mkAfter ''
    install -m 0644 ${webInventory} /var/lib/server-monitoring/.web-inventory.tmp
    mv -f /var/lib/server-monitoring/.web-inventory.tmp /var/lib/server-monitoring/web-inventory.prom
  '';
  systemd.services.server-monitoring-inventory.restartTriggers = [webInventory];

  # Generate on the server, not during evaluation/build; never print or put secrets in the store.
  systemd.services.grafana-bootstrap = {
    description = "Create persistent Grafana bootstrap credentials once";
    before = ["grafana.service"];
    requiredBy = ["grafana.service"];
    path = [
      pkgs.openssl
      pkgs.coreutils
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
      Group = "grafana";
      StateDirectory = "grafana-bootstrap";
      StateDirectoryMode = "0750";
      UMask = "0027";
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
    script = ''
      for name in admin-password secret-key; do
        if [ ! -s ${secretDir}/"$name" ]; then
          openssl rand -hex 32 > ${secretDir}/."$name".tmp
          chmod 0640 ${secretDir}/."$name".tmp
          mv ${secretDir}/."$name".tmp ${secretDir}/"$name"
        fi
      done
    '';
  };
  systemd.services.grafana = {
    requires = ["grafana-bootstrap.service"];
    after = ["grafana-bootstrap.service"];
  };
  services.grafana = {
    enable = true;
    openFirewall = false;
    # This Grafana version distributes its native Prometheus datasource as a
    # preinstalled plugin. Keep only that required datasource; no extra apps.
    declarativePlugins = [pkgs.grafanaPlugins.prometheus];
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
        domain = "dashboard.theswisscheese.com";
        root_url = "https://dashboard.theswisscheese.com/";
        enforce_domain = true;
      };
      security = {
        admin_user = "admin";
        admin_password = "$__file{${secretDir}/admin-password}";
        secret_key = "$__file{${secretDir}/secret-key}";
        cookie_secure = true;
        cookie_samesite = "lax";
        disable_gravatar = true;
      };
      users = {
        allow_sign_up = false;
        allow_org_create = false;
      };
      "auth.anonymous".enabled = false;
      auth.disable_login_form = false;
      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
        check_for_plugin_updates = false;
        feedback_links_enabled = false;
      };
      dashboards.default_home_dashboard_path = "${dashboardDir}/home.json";
    };
    provision = {
      enable = true;
      datasources.settings = {
        apiVersion = 1;
        datasources = [
          {
            name = "Servers";
            uid = "server-prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:9090";
            isDefault = true;
            editable = false;
            jsonData.timeInterval = "15s";
          }
        ];
      };
      dashboards.settings = {
        apiVersion = 1;
        providers = [
          {
            name = "Home servers";
            type = "file";
            disableDeletion = true;
            allowUiUpdates = false;
            options.path = dashboardDir;
          }
        ];
      };
    };
  };
  services.nginx.virtualHosts."dashboard.theswisscheese.com" = {
    forceSSL = true;
    enableACME = true;
    # Nginx's access module checks the socket peer. No real_ip/X-Forwarded-For trust.
    extraConfig = ''
      allow 10.24.24.0/24;
      allow 127.0.0.1;
      allow ::1;
      deny all;
    '';
    locations."/" = {
      proxyPass = "http://127.0.0.1:3000";
      # Preserve the public Host and HTTPS scheme for Grafana's domain enforcement.
      recommendedProxySettings = true;
      proxyWebsockets = true;
    };
  };
  security.acme.certs."dashboard.theswisscheese.com" = {
    webroot = null;
    dnsProvider = "cloudflare";
  };
}
