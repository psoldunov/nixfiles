{
  config,
  libs,
  pkgs,
  ...
}: let
  vpn_connect = pkgs.writeShellScriptBin "waybar_vpn-connect" ''
    vpn_status=$(${pkgs.expressvpn}/bin/expressvpn status)

    if echo "$vpn_status" | grep -q "Not connected"; then
      ${pkgs.expressvpn}/bin/expressvpn connect >/dev/null 2>&1
    else
      ${pkgs.expressvpn}/bin/expressvpn disconnect >/dev/null 2>&1
    fi

    pkill -RTMIN+1 waybar
  '';

  vpn_status = pkgs.writeShellScriptBin "waybar_vpn-status" ''
    vpn_status=$(${pkgs.expressvpn}/bin/expressvpn status 2>&1)

    if echo "$vpn_status" | grep -q "Not connected"; then
        echo '{"text": "VPN disconnected", "alt": "disconnected", "tooltip": "Not connected", "class": "disconnected", "percentage": ""}' | jq --unbuffered --compact-output
    else
        tooltip_text=$(echo "$vpn_status" | grep -o "Connected to [^[:space:]]\+" | sed -r "s/\x1B\[[0-9;]*m//g")

        echo '{"text": "VPN connected", "alt": "connected", "tooltip": "'"$tooltip_text"'", "class": "connected", "percentage": ""}' | jq --unbuffered --compact-output
    fi
  '';
in {
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      target = "tray.target";
    };
    settings = {
      main = {
        height = 42;
        position = "bottom";
        layer = "top";
        margin-left = 4;
        margin-top = 0;
        margin-right = 4;
        margin-bottom = 4;
        spacing = 4;
        modules-left = ["custom/logo" "hyprland/workspaces" "wlr/taskbar" "hyprland/window"];
        modules-right = [
          "mpd"
          "custom/wf-recorder"
          "custom/updates"
          "custom/vpn"
          "idle_inhibitor"
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "temperature"
          "keyboard-state"
          "hyprland/language"
          "clock"
          "clock#clock2"
          "tray"
          "custom/exit"
          "custom/notification"
        ];
        "hyprland/workspaces" = {
          format = "{name}";
        };
        "custom/vpn" = {
          format = "VPN {icon}";
          tooltip-format = "{}";
          return-type = "json";
          exec = "${vpn_status}/bin/waybar_vpn-status";
          restart = 60;
          signal = 1;
          on-click = "${vpn_connect}/bin/waybar_vpn-connect";
          format-icons = {
            connected = "󰌾";
            disconnected = "󰿆";
          };
          tooltip = true;
        };
        "custom/wf-recorder" = {
          format = "{}";
          interval = 1;
          exec = "echo ''";
          tooltip = "false";
          exec-if = "pgrep wf-recorder";
          on-click = "record_screen";
          signal = 8;
        };
        "custom/notification" = {
          tooltip = true;
          format = "{icon}  {}";
          format-icons = {
            notification = "<span foreground='red'><sup></sup></span>";
            none = "";
            dnd-notification = "<span foreground='red'><sup></sup></span>";
            dnd-none = "";
            inhibited-notification = "<span foreground='red'><sup></sup></span>";
            inhibited-none = "";
            dnd-inhibited-notification = "<span foreground='red'><sup></sup></span>";
            dnd-inhibited-none = "";
          };
          return-type = "json";
          exec-if = "which swaync-client";
          exec = "${pkgs.swaynotificationcenter}/bin/swaync-client -swb";
          on-click = "sleep 0.1; ${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
          on-click-right = "${pkgs.swaynotificationcenter}/bin/swaync-client -d -sw";
          escape = true;
        };
        "custom/logo" = {
          format = "   ";
          tooltip = false;
          on-click-right = "kitty -e --hold fastfetch";
          on-click = "sleep 0.1; rofi -show drun";
        };
        "wlr/taskbar" = {
          format = "{icon}";
          icon-size = 18;
          tooltip-format = "{title}";
          on-click = "activate";
          on-click-middle = "close";
          ignore-list = [
            "kitty"
            "Spotify"
            "xwaylandvideobridge"
            "org.speedcrunch."
          ];
        };
        "custom/exit" = {
          format = "";
          on-click = "wlogout";
          tooltip = false;
        };
        "keyboard-state" = {
          numlock = false;
          capslock = true;
          format = "{name} {icon}";
          format-icons = {
            locked = "";
            unlocked = "";
          };
        };
        mpd = {
          format = "{stateIcon} {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) ";
          format-disconnected = "Disconnected ";
          format-stopped = "";
          unknown-tag = "N/A";
          interval = 2;
          on-click = "${pkgs.mpc-cli}/bin/mpc toggle";
          on-click-right = "fish -c '${pkgs.hyprland}/bin/hyprctl dispatch focuswindow title:(mpc status | head -n 1)'";
          on-click-middle = "kitty -e ${pkgs.ncmpcpp}/bin/ncmpcpp";
          on-scroll-down = "${pkgs.mpc-cli}/bin/mpc next";
          on-scroll-up = "${pkgs.mpc-cli}/bin/mpc prev";
          consume-icons = {
            on = " ";
          };
          random-icons = {
            off = "<span color=\"#f53c3c\"></span> ";
            on = " ";
          };
          repeat-icons = {
            on = " ";
          };
          single-icons = {
            on = "1 ";
          };
          state-icons = {
            paused = "";
            playing = "";
          };
          tooltip-format = "MPD (connected)";
          tooltip-format-disconnected = "MPD (disconnected)";
        };
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "";
            deactivated = "";
          };
        };
        tray = {
          spacing = 10;
        };
        cpu = {
          format = "{usage}% ";
          tooltip = false;
        };
        memory = {
          format = "{}% ";
        };
        temperature = {
          critical-threshold = 80;
          format = ''{temperatureC}°C {icon}'';
          format-icon = [
            ""
            ""
            ""
          ];
        };
        network = {
          format-wifi = "{essid} ({signalStrength}%) ";
          format-ethernet = "{ipaddr}/{cidr} ";
          tooltip-format = "{ifname} via {gwaddr} ";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "Disconnected ⚠";
          format-alt = "{ifname} = {ipaddr}/{cidr}";
        };
        pulseaudio = {
          format = "{volume}% {icon} {format_source}";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-muted = " {format_source}";
          format-source = "{volume}% ";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
              ""
            ];
          };
          on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
        };
        "hyprland/language" = {
          format = "{}";
          format-en = "EN";
          format-ru = "RU";
        };
        clock = {
          clock = "clock1";
          timezone = "Europe/Tallinn";
        };
        "clock#clock2" = {
          clock = "clock2";
          timezone = "Europe/Tallinn";
          format = "{:%d/%m/%Y}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };
      };
    };
    style = ''
      @import url("file://${config.xdg.cacheHome}/wal/colors-waybar.css");

      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 14px;
        font-weight: 700;
      }

      window {
        border-radius: 8px;
        border: 2px solid @color4;
        background-color: @background;
        color: @foreground;
      }

      button {
        box-shadow: none;
        border: none;
        border-radius: 8px;
      }

      #workspaces {
        background-color: @foreground;
        margin: 6px 0;
        border-radius: 4px;
      }

      #workspaces button {
        background-color: transparent;
        color: @background;
        border-radius: 4px;
      }

      #workspaces button:hover {
        background: rgba(0, 0, 0, 0.2);
      }

      #workspaces button.urgent {
        background-color: @color2;
      }

      #workspaces button.active {
        background-color: rgba(4, 97, 150, 0.5);
        color: white;
      }

      #taskbar {
        background-color: @background;
        margin: 6px 0;
        border-radius: 4px;
      }

      #taskbar button {
        background-color: transparent;
        border-radius: 4px;
      }

      #taskbar button:hover {
        background: rgba(255, 255, 255, 0.2);
      }

      button:hover {
        box-shadow: inherit;
        text-shadow: inherit;
        background: inherit;
      }

      #tray * {
        border-width: 0;
      }

      #tray menu {
        border-radius: 8px;
      }

      #custom-spotify {
        background-color: #1db954;
        color: @background;
        padding: 0 10px 0 10px;
        margin: 6px 0;
        border-radius: 4px;
      }
      #custom-spotify.paused {
        background-color: #90b1b1;
      }

      #custom-wf-recorder {
        background-color: #ff5722;
        color: @background;
        padding: 0 16px 0 14px;
        margin: 6px 0;
        border-radius: 4px;
      }

      #custom-updates {
        background-color: @color7;
        font-weight: 600;
        color: @background;
        padding: 0 8px;
        margin: 6px 0;
        border-radius: 4px;
      }

      #custom-vpn {
        font-weight: 600;
        color: @background;
        background-color: @color7;
        padding: 0 10px 0 8px;
        margin: 6px 0;
        border-radius: 4px;
      }

      #custom-vpn.connected {
        background-color: #18e37e;
      }

      #custom-vpn.disconnected {
        background-color: #f53c3c;
        color: #fff;
      }

      #custom-updates.green {
        background-color: @color7;
      }

      #custom-updates.yellow {
        background-color: #ff9a3c;
        color: #ffffff;
      }

      #custom-updates.red {
        background-color: #dc2f2f;
        color: #ffffff;
      }

      #custom-logo {
        margin: 0 6px 0 12px;
        background-image: url("${config.xdg.configHome}/waybar/icons/nixos.svg");
        background-position: center;
        background-repeat: no-repeat;
        background-size: contain;
      }

      #tray {
        background-color: @color8;
        padding: 0 8px;
        margin: 6px 0;
        border-radius: 4px;
      }

      #custom-exit {
        background-color: @color2;
        color: @background;
        padding: 0 16px 0 14px;
        margin: 6px 0;
        border-radius: 4px;
      }

      #idle_inhibitor {
        background-color: @color12;
        color: #ffffff;
        padding: 0 16px 0 12px;
        margin: 6px 0;
        border-radius: 4px;
      }

      #idle_inhibitor.activated {
        background-color: #ecf0f1;
        color: @background;
      }

      #language {
        margin: 6px 0;
        border-radius: 4px;
        padding: 0 10px 0 10px;
        background: #1db954;
        color: @background;
      }

      #keyboard-state {
        background: #97e1ad;
        color: @background;
        margin: 6px 0;
        border-radius: 4px;
      }

      #keyboard-state > label {
        padding: 0 14px 0 10px;
      }

      #keyboard-state > label.locked {
        background: rgba(0, 0, 0, 0.2);
      }

      #custom-notification {
        background-color: #ffffff;
        color: @background;
        padding: 0 10px 0 10px;
        margin: 6px 6px 6px 0px;
        border-radius: 4px;
      }

      #clock {
        background-color: #64727d;
        color: #fff;
        padding: 0 10px 0 10px;
        margin: 6px 0;
        border-radius: 4px;
      }

      #clock.clock2 {
        background-color: #64727d;
        color: #fff;
        padding: 0 10px 0 10px;
        margin: 6px 0;
        border-radius: 4px;
      }

      #mpd {
        background-color: #18e37e;
        color: @background;
        padding: 0 10px 0 10px;
        margin: 6px 0;
        border-radius: 4px;
      }

      #mpd.disconnected {
        background-color: #f53c3c;
      }

      #mpd.stopped {
        background-color: #90b1b1;
      }

      #mpd.paused {
        background-color: #51a37a;
      }

      #cpu {
        background-color: #2ecc71;
        color: @background;
        padding: 0 10px 0 10px;
        margin: 6px 0;
        border-radius: 4px;
      }

      #memory {
        background-color: #9b59b6;
        color: #ffffff;
        padding: 0 10px 0 10px;
        margin: 6px 0;
        border-radius: 4px;
      }

      #disk {
        background-color: #964b00;
        color: #ffffff;
        padding: 0 10px 0 10px;
        margin: 6px 0;
        border-radius: 4px;
      }

      #temperature {
        background-color: #f0932b;
        color: @background;
        padding: 0 10px 0 10px;
        margin: 6px 0;
        border-radius: 4px;
      }

      #network {
        background-color: #2980b9;
        color: #ffffff;
        padding: 0 10px 0 10px;
        margin: 6px 0;
        border-radius: 4px;
      }

      #network.disconnected {
        background-color: #f53c3c;
        padding: 0 10px 0 10px;
        margin: 6px 0;
        border-radius: 4px;
      }

      #pulseaudio {
        background-color: #f1c40f;
        color: #000000;
        padding: 0 10px 0 10px;
        margin: 6px 0;
        border-radius: 4px;
      }

      #pulseaudio.muted {
        background-color: #90b1b1;
        color: #2a5c45;
        padding: 0 10px 0 10px;
        margin: 6px 0;
        border-radius: 4px;
      }

    '';
  };

  services.pasystray = {
    enable = true;
    extraOptions = ["--notify=none"];
  };

  home.file = {
    "${config.xdg.configHome}/waybar/icons/nixos.svg" = {
      text = ''
        <svg width="117" height="117" viewBox="0 0 117 117" fill="none" xmlns="http://www.w3.org/2000/svg">
        <g clip-path="url(#clip0_1_7)">
        <path fill-rule="evenodd" clip-rule="evenodd" d="M35.6959 59.7519L64.193 109.116L51.0967 109.239L43.4881 95.9763L35.8256 109.167L29.3192 109.165L25.9864 103.407L36.903 84.6361L29.1542 71.1515L35.6959 59.7519Z" fill="#5277C3"/>
        <path fill-rule="evenodd" clip-rule="evenodd" d="M45.9817 39.4181L17.479 88.7795L10.8245 77.4985L18.506 64.2796L3.25088 64.2396L0 58.6031L3.32055 52.8379L25.0343 52.9061L32.8376 39.4525L45.9817 39.4181Z" fill="#7EBAE4"/>
        <path fill-rule="evenodd" clip-rule="evenodd" d="M48.168 78.8765L105.167 78.88L98.7252 90.2829L83.4359 90.2406L91.0288 103.471L87.7732 109.105L81.1196 109.113L70.3225 90.2735L54.7692 90.2418L48.168 78.8765Z" fill="#7EBAE4"/>
        <path fill-rule="evenodd" clip-rule="evenodd" d="M81.3429 57.2482L52.8458 7.88442L65.942 7.76141L73.5506 21.0238L81.2132 7.83196L87.7196 7.83429L91.0527 13.5927L80.1358 32.3628L87.8846 45.8485L81.3429 57.2482Z" fill="#7EBAE4"/>
        <path fill-rule="evenodd" clip-rule="evenodd" d="M35.6959 59.7519L64.193 109.116L51.0968 109.239L43.4881 95.9763L35.8256 109.167L29.3192 109.165L25.9864 103.407L36.903 84.6361L29.1542 71.1515L35.6959 59.7519Z" fill="#5277C3"/>
        <path fill-rule="evenodd" clip-rule="evenodd" d="M68.7956 37.9982L11.7958 37.995L18.2384 26.5918L33.5279 26.6352L25.9351 13.4035L29.1906 7.76922L35.8428 7.76251L46.6411 26.6011L62.1935 26.6329L68.7956 37.9982Z" fill="#5277C3"/>
        <path fill-rule="evenodd" clip-rule="evenodd" d="M71.0183 77.5703L99.521 28.21L106.175 39.4901L98.494 52.7103L113.749 52.7502L117 58.3868L113.68 64.1519L91.9657 64.0825L84.1624 77.5361L71.0183 77.5703Z" fill="#5277C3"/>
        </g>
        <defs>
        <clipPath id="clip0_1_7">
        <rect width="117" height="117" fill="white"/>
        </clipPath>
        </defs>
        </svg>
      '';
    };
  };
}
