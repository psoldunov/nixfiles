# One native Grafana overview: stable datasource UID, explicit failure/no-data labels.
{
  lib,
  services,
  dns,
}: let
  ds = {
    type = "prometheus";
    uid = "server-prometheus";
  };
  target = expr: legend: {
    inherit expr;
    legendFormat = legend;
    datasource = ds;
  };
  panel = id: title: type: x: y: w: h: {
    inherit id title type;
    datasource = ds;
    gridPos = {
      inherit
        x
        y
        w
        h
        ;
    };
    fieldConfig = {
      defaults = {
        noValue = "NO DATA";
      };
      overrides = [];
    };
  };
  history = id: title: x: y: expr: legend: unit:
    (panel id title "timeseries" x y 12 8)
    // {
      targets = [(target expr legend)];
      fieldConfig.defaults =
        {
          inherit unit;
          noValue = "NO DATA";
          color.mode = "palette-classic";
          custom = {
            drawStyle = "line";
            lineWidth = 2;
            fillOpacity = 6;
            spanNulls = false;
          };
        }
        // lib.optionalAttrs (unit == "percent") {
          min = 0;
          max = 100;
        };
      options = {
        legend = {
          displayMode = "table";
          placement = "bottom";
          calcs = [
            "lastNotNull"
            "max"
          ];
        };
        tooltip.mode = "multi";
      };
    };
  table = id: title: x: y: w: h: expr:
    (panel id title "table" x y w h)
    // {
      targets = [
        (
          (target expr "")
          // {
            format = "table";
            instant = true;
          }
        )
      ];
      options = {
        showHeader = true;
        cellHeight = "sm";
        footer.show = false;
      };
    };
  statusMapping = values: [
    {
      type = "value";
      options = values;
    }
  ];
  unitExpr = host: ''(node_systemd_unit_state{state=~"active|activating|deactivating|failed|inactive",host="${host}"} == 1) * on(host,name) group_left(mode) server_expected_unit_info or on(host,name) label_replace(server_expected_unit_info{host="${host}"} unless on(host,name) node_systemd_unit_state{host="${host}"}, "state", "MISSING / NO DATA", "name", ".*")'';
  unitTable = id: host: x:
    (table id "${host} · service unit states" x 60 12 18 (unitExpr host))
    // {
      description = "Process state only, separate from HTTP. Expected units remain listed if missing. For scheduled jobs inactive means idle, not broken. An exporter outage means NO DATA, never healthy.";
      transformations = [
        {
          id = "organize";
          options = {
            excludeByName = {
              Time = true;
              __name__ = true;
              instance = true;
              job = true;
              Value = true;
              host = true;
            };
            indexByName = {
              name = 0;
              state = 1;
              mode = 2;
            };
            renameByName = {
              name = "Unit";
              state = "State";
              mode = "Expected lifecycle";
            };
          };
        }
      ];
    };
  mountSelector = ''job="node",mountpoint=~"/|/RAID|/volume1",fstype=~"ext4|btrfs"'';
  # No fallback to statvfs(/volume1): an unmounted nofail volume must fail, not show root capacity.
  mounted = host: mount: ''(max(node_filesystem_size_bytes{host="${host}",mountpoint="${mount}",fstype=~"ext4|btrfs"} > bool 0) or vector(0)) and on() (up{job="node",host="${host}"} == 1)'';
  readiness = id: host: x:
    (panel id "${host} · telemetry" "stat" x 4 12 4)
    // {
      targets = [
        (target ''up{job="node",host="${host}"}'' "Node scrape")
        (target ''(server_intel_gpu_sample_success{host="${host}"} * (time() - server_intel_gpu_last_success_timestamp_seconds{host="${host}"} < bool 60)) or on(host) (0 * up{job="node",host="${host}"})'' "Intel GPU sample (<60s)")
      ];
      fieldConfig.defaults = {
        noValue = "NO DATA";
        mappings = statusMapping {
          "0" = {
            text = "DOWN / STALE";
            color = "red";
          };
          "1" = {
            text = "READY";
            color = "green";
          };
        };
      };
      options = {
        colorMode = "value";
        graphMode = "none";
        textMode = "value_and_name";
        reduceOptions = {
          calcs = ["last"];
          values = false;
        };
      };
    };
  # One stat per server and check. A probe Prometheus has no sample for
  # shows NO DATA instead of vanishing from the panel.
  dnsStatus = id: x: y:
    (panel id "DNS · ${lib.concatMapStringsSep ", " (s: "${s.host} ${s.role}") dns.servers}" "stat" x y 12 8)
    // {
      description = "Blackbox queries from BigTasty to each server's LAN address, as clients do. The public name proves recursion works; the local rewrite proves AdGuard's policy is loaded.";
      targets = lib.concatMap (s:
        map (c:
          target ''max(probe_success{job="dns",host="${s.host}",check="${c.name}"}) or vector(-1)''
          "${s.host} · ${c.name}")
        dns.checks)
      dns.servers;
      fieldConfig.defaults = {
        noValue = "NO DATA";
        mappings = statusMapping {
          "-1" = {
            text = "NO DATA / PROBE DOWN";
            color = "orange";
          };
          "0" = {
            text = "FAILING";
            color = "red";
          };
          "1" = {
            text = "ANSWERING";
            color = "green";
          };
        };
      };
      options = {
        colorMode = "value";
        graphMode = "none";
        textMode = "value_and_name";
        reduceOptions = {
          calcs = ["last"];
          values = false;
        };
      };
    };
in {
  uid = "home-servers";
  title = "Home servers";
  description = "BigTasty + BigKing · home-network telemetry, local service reachability and DNS";
  schemaVersion = 39;
  version = 1;
  editable = false;
  refresh = "30s";
  timezone = "browser";
  time = {
    from = "now-6h";
    to = "now";
  };
  tags = [
    "home"
    "servers"
  ];
  links = [
    {
      title = "Uptime Kuma";
      type = "link";
      url = "https://kuma.theswisscheese.com";
      targetBlank = true;
    }
  ];
  panels =
    map
    (
      p:
        if p ? targets
        then
          p
          // {
            targets =
              lib.imap0 (
                i: t:
                  t
                  // {refId = builtins.elemAt ["A" "B" "C" "D"] i;}
                  // lib.optionalAttrs (p.type == "stat") {
                    instant = true;
                    range = false;
                  }
              )
              p.targets;
          }
        else p
    )
    [
      (
        (panel 1 "Home network · BigTasty & BigKing" "text" 0 0 24 4)
        // {
          options = {
            mode = "markdown";
            content = ''
              **Telemetry → capacity → DNS → services.** Refreshes every 30s; metrics every 15s. Home LAN only; Grafana login required.

              **READY** means a recent scrape/sample, **DOWN / STALE** needs investigation, **NO DATA** is unknown, not healthy. Unit state and HTTP response are separate checks. HTTP authentication/redirect responses count as responding; no app credentials are tested. Native Grafana time controls apply to all histories.
            '';
          };
        }
      )
      (readiness 2 "BigTasty" 0)
      (readiness 3 "BigKing" 12)
      (
        history 4 "CPU · busy, not load average" 0 8
        ''100 * (1 - avg by(host) (rate(node_cpu_seconds_total{job="node",mode="idle"}[2m])))''
        "{{host}}"
        "percent"
      )
      (
        history 5 "Memory · used (available-aware)" 12 8
        ''100 * (1 - node_memory_MemAvailable_bytes{job="node"} / node_memory_MemTotal_bytes{job="node"})''
        "{{host}}"
        "percent"
      )
      (
        (table 6 "Local storage · available / used / capacity" 0 16 16 8 "")
        // {
          targets =
            lib.imap0
            (i: metric: {
              refId = builtins.elemAt ["A" "B" "C"] i;
              expr = metric;
              format = "table";
              instant = true;
              datasource = ds;
            })
            [
              "max by(host,mountpoint) (node_filesystem_avail_bytes{${mountSelector}})"
              "max by(host,mountpoint) (node_filesystem_size_bytes{${mountSelector}} - node_filesystem_free_bytes{${mountSelector}})"
              "max by(host,mountpoint) (node_filesystem_size_bytes{${mountSelector}})"
            ];
          fieldConfig.defaults = {
            unit = "bytes";
            noValue = "NO DATA";
          };
          transformations = [
            {
              id = "merge";
              options = {};
            }
            {
              id = "organize";
              options = {
                excludeByName = {
                  Time = true;
                  __name__ = true;
                  job = true;
                  instance = true;
                  device = true;
                  fstype = true;
                  device_error = true;
                };
                indexByName = {
                  host = 0;
                  mountpoint = 1;
                  "Value #A" = 2;
                  "Value #B" = 3;
                  "Value #C" = 4;
                };
                renameByName = {
                  host = "Server";
                  mountpoint = "Mount";
                  "Value #A" = "Available";
                  "Value #B" = "Used";
                  "Value #C" = "Capacity";
                };
              };
            }
          ];
          description = "Only /, /RAID, /volume1 physical ext4/btrfs mounts; excludes NFS, bind mounts and Docker. Available is unprivileged free space; used = capacity - filesystem free.";
        }
      )
      (
        (panel 7 "Required mounts · absent is failure" "stat" 16 16 8 8)
        // {
          targets = [
            (target (mounted "BigTasty" "/") "BigTasty /")
            (target (mounted "BigTasty" "/RAID") "BigTasty /RAID")
            (target (mounted "BigKing" "/") "BigKing /")
            (target (mounted "BigKing" "/volume1") "BigKing /volume1")
          ];
          fieldConfig.defaults = {
            noValue = "NO DATA / NODE DOWN";
            mappings = statusMapping {
              "0" = {
                text = "NOT MOUNTED";
                color = "red";
              };
              "1" = {
                text = "MOUNTED";
                color = "green";
              };
            };
          };
          options = {
            colorMode = "value";
            graphMode = "none";
            textMode = "value_and_name";
            reduceOptions = {
              calcs = ["last"];
              values = false;
            };
          };
        }
      )
      (
        history 8 "BigTasty · CPU / drives / available sensors" 0 24
        ''node_hwmon_temp_celsius{host="BigTasty"} * on(host,chip) group_left(chip_name) node_hwmon_chip_names''
        "{{chip_name}} · {{chip}} / {{sensor}}"
        "celsius"
      )
      (
        history 9 "BigKing · CPU / NVMe / HDD sensors" 12 24
        ''node_hwmon_temp_celsius{host="BigKing"} * on(host,chip) group_left(chip_name) node_hwmon_chip_names''
        "{{chip_name}} · {{chip}} / {{sensor}}"
        "celsius"
      )
      (
        (
          history 10 "BigTasty · Intel engine busy" 0 32
          ''server_intel_gpu_engine_busy_percent{host="BigTasty"} and on(host) (server_intel_gpu_sample_success == 1) and on(host) (time() - server_intel_gpu_last_success_timestamp_seconds < 60)''
          "{{device}} · {{engine}}"
          "percent"
        )
        // {
          description = "Actual intel_gpu_top engine busy; engines are independent, never summed. Failed/stale samples leave a gap. GPU temperature is unavailable unless hardware exports a separate sensor.";
        }
      )
      (
        history 11 "BigKing · Intel engine busy" 12 32
        ''server_intel_gpu_engine_busy_percent{host="BigKing"} and on(host) (server_intel_gpu_sample_success == 1) and on(host) (time() - server_intel_gpu_last_success_timestamp_seconds < 60)''
        "{{device}} · {{engine}}"
        "percent"
      )
      (dnsStatus 16 0 40)
      (
        history 17 "DNS · lookup time from BigTasty" 12 40
        ''probe_dns_lookup_time_seconds{job="dns"}''
        "{{host}} · {{check}}"
        "s"
      )
      (
        (
          table 12 "Web origins · responding ≠ authenticated app health" 0 48 24 12
          ''max by(host,service,name,url) (probe_success{job="web-reachability"}) or on(host,service,name,url) (-1 * server_expected_web_info)''
        )
        // {
          fieldConfig = {
            defaults.noValue = "NO DATA";
            overrides = [
              {
                matcher = {
                  id = "byName";
                  options = "HTTP reachability";
                };
                properties = [
                  {
                    id = "mappings";
                    value = statusMapping {
                      "-1" = {
                        text = "NO DATA / PROBE DOWN";
                        color = "orange";
                      };
                      "0" = {
                        text = "NOT RESPONDING";
                        color = "red";
                      };
                      "1" = {
                        text = "RESPONDING";
                        color = "green";
                      };
                    };
                  }
                ];
              }
              {
                matcher = {
                  id = "byName";
                  options = "url";
                };
                properties = [
                  {
                    id = "links";
                    value = [
                      {
                        title = "Open service";
                        url = "\${__value.raw}";
                        targetBlank = true;
                      }
                    ];
                  }
                ];
              }
            ];
          };
          transformations = [
            {
              id = "organize";
              options = {
                excludeByName = {
                  Time = true;
                  __name__ = true;
                  job = true;
                  instance = true;
                };
                indexByName = {
                  service = 0;
                  Value = 1;
                  name = 2;
                  url = 3;
                  host = 4;
                };
                renameByName.Value = "HTTP reachability";
              };
            }
          ];
        }
      )
      (unitTable 13 "BigTasty" 0)
      (unitTable 14 "BigKing" 12)
      (
        (panel 15 "Launch catalog · configured links, not live verification" "text" 0 78 24 16)
        // {
          options = {
            mode = "markdown";
            content = ''
              | Application | Process unit | Scope / caveat |
              | --- | --- | --- |
              ${lib.concatMapStringsSep "\n" (
                  s: "| [${s.name}](${s.url}) | `${s.unit}.service` | ${s.note} |"
                )
                services}

              **No invented admin pages:** Concierge sync, FlareSolverr integration API and Sons of the Forest UDP server appear in process inventory only. NFS and Samba are checked by their service units, not fake UI probes. AdGuard has no web link: its policy lives in Nix, and the DNS panels query PiHome and BigTasty directly. Existing Homarr and Uptime Kuma remain unchanged.
            '';
          };
        }
      )
    ];
}
