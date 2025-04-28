{
  config,
  inputs,
  pkgs,
  lib,
  globalSettings,
  pkgs-stable,
  ...
}: let
  windowRules = import ./hypr-modules/windowrules.nix;
  keyBinds = import ./hypr-modules/keybinds.nix {
    inherit config;
    inherit pkgs;
    inherit pkgs-stable;
  };

  discordVencord = pkgs.discord-canary.override {
    withVencord = true;
    withOpenASAR = true;
  };

  startupSound = ./assets/startup.wav;

  # wallpaperPath = pkgs.fetchurl {
  #   url = "https://i.imgur.com/iahzUAJ.jpeg";
  #   sha256 = "1baa1nrgrs1cz9yf7jiag6w1jznxdj5g18c9i9wjmqc927kb1jy6";
  # };

  wallpaperPath = ./assets/wallpaper.jpg;

  autoStart = pkgs.writeShellScript "autostart_applications" ''
    autostart_commands="
      ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
      ${pkgs.ydotool}/bin/ydotoold
      ${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store
      ${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store
      ${pkgs.solaar}/bin/solaar -w hide
      ${pkgs.slack}/bin/slack -u
      ${pkgs.ferdium}/bin/ferdium
      ${pkgs.telegram-desktop}/bin/telegram-desktop -startintray
      ${pkgs.localsend}/bin/localsend_app --hidden
      ${pkgs.motrix}/bin/motrix --ozone-platform-hint=auto
      ${pkgs._1password-gui}/bin/1password --silent
      ${discordVencord}/bin/discordcanary --start-minimized
      ${pkgs.zapzap}/bin/zapzap
      steam -silent
    "

    sleep 10

    echo "$autostart_commands" | while read -r cmd; do
        eval "$cmd &"
    done
  '';
in {
  services.mpris-proxy.enable = true;

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = ["${wallpaperPath}"];
      wallpaper = [
        "HDMI-A-1,${wallpaperPath}"
      ];
    };
  };

  wayland.windowManager.hyprland = {
    enable = globalSettings.enableHyprland;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    systemd = {
      enable = true;
      enableXdgAutostart = true;
    };
    xwayland.enable = true;
    settings =
      {
        source = [
          "${config.xdg.configHome}/hypr/exec.conf"
        ];
        monitor = [
          "DP-1,3840x2160@144,0x0,1,,,cm,auto"
          "HDMI-A-1,3840x2160@120,0x0,1.066667,,,cm,auto"
        ];
        ecosystem = {
          no_update_news = true;
        };
        input = {
          kb_layout = "us,ru";
          kb_options = "grp:alt_space_toggle, compose:rctrl";
          kb_variant = ",mac";
          follow_mouse = true;
          mouse_refocus = false;
          scroll_factor = "0.75";
          natural_scroll = "yes";
          sensitivity = 0;
          accel_profile = "adaptive";
          touchpad = {
            natural_scroll = "yes";
          };
        };
        render = {
          # explicit_sync = 0;
        };
        general = {
          gaps_in = 4;
          gaps_out = 4;
          border_size = 2;
          "col.active_border" = "rgb(fcfdfc)";
          "col.inactive_border" = "rgb(2d3b53)";
          layout = "dwindle";
        };

        xwayland = {
          force_zero_scaling = true;
        };
        decoration = {
          rounding = 4;
          # screen_shader = "${config.xdg.configHome}/hypr/shaders/screenShader.frag";
        };
        animations = {
          enabled = "yes";
          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
          animation = [
            "windows, 1, 7, myBezier"
            "windowsOut, 1, 7, default, popin 80%"
            "border, 1, 10, default"
            "borderangle, 1, 8, default"
            "fade, 1, 7, default"
            "workspaces, 1, 6, default"
          ];
        };
        dwindle = {
          pseudotile = "yes";
          # preserve_split = "yes";
        };
        # master = {
        #   new_is_master = true;
        # };
        debug = {
          overlay = "off";
        };
        misc = {
          focus_on_activate = true;
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          allow_session_lock_restore = true;
          anr_missed_pings = 4;
          vrr = 1;
          key_press_enables_dpms = true;
        };
        experimental = {
          # wide_color_gamut = true;
          # hdr = true;
          # xx_color_management_v4 = true;
        };
        device = [
          {
            name = "dualsense-wireless-controller-touchpad";
            enabled = 0;
          }
        ];
      }
      // windowRules
      // keyBinds;
  };

  xdg = {
    mime.enable = true;
  };

  home.sessionVariables = {
    HYPRCURSOR_THEME = "catppuccin-mocha-dark-cursors";
    HYPRCURSOR_SIZE = lib.mkForce "24";
    ASAN_OPTIONS = "log_path=~/asan.log";
    MOZ_ENABLE_WAYLAND = 1;
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
    QT_QPA_PLATFORM = "wayland;xcb";
    GDK_BACKEND = "wayland,x11";
    CLUTTER_BACKEND = "wayland";
    SDL_VIDEODRIVER = "wayland,x11,windows";
  };

  home.file = lib.mkIf globalSettings.enableHyprland {
    "${config.xdg.configHome}/hypr/exec.conf" = {
      text = ''
        exec-once = ${config.programs.ags.finalPackage}/bin/ags
        # exec-once = start_static_wallpaper ${wallpaperPath}
        exec-once = ${pkgs.sox}/bin/play ${startupSound}
        exec-once = ${autoStart}
      '';
    };
  };
}
