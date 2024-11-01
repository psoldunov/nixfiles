{
  config,
  inputs,
  pkgs,
  pkgs-stable,
  ...
}: let
  wallpaperPath = "/home/psoldunov/Pictures/Wallpapers/porsche-uw.jpg";
  windowRules = import ./hypr-modules/windowrules.nix;
  keyBinds = import ./hypr-modules/keybinds.nix {
    inherit config;
    inherit pkgs;
    inherit pkgs-stable;
  };

  startupSound = ./assets/startup.wav;

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
      1password --silent
      steam -silent
      vesktop --start-minimized
    "

    sleep 10

    echo "$autostart_commands" | while read -r cmd; do
        eval "$cmd &"
    done
  '';
in {
  services.mpris-proxy.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;
    catppuccin.enable = false;
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
        monitor = "DP-1,preferred,auto,1";
        input = {
          kb_layout = "us,ru";
          kb_variant = ",mac";
          follow_mouse = true;
          mouse_refocus = false;
          scroll_factor = "0.75";
          natural_scroll = "yes";
          # mouse_refocus = false;
          sensitivity = 0;
          accel_profile = "adaptive";
          touchpad = {
            natural_scroll = "yes";
          };
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
          drop_shadow = "yes";
          shadow_range = 4;
          shadow_render_power = 4;
          "col.shadow" = "rgba(1a1a1aee)";
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
          pseudotile = "yes"; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds
          # preserve_split = "yes"; # you probably want this
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
          vrr = 2;
          # vrr = 0;
          # mouse_move_enables_dpms = true;
          key_press_enables_dpms = true;
        };
        device = [
          {
            name = "by-tech-air75";
            kb_options = "grp:ctrl_space_toggle, compose:rctrl";
          }

          {
            name = "dualsense-wireless-controller-touchpad";
            enabled = 0;
          }

          {
            name = "by-tech-air75-1";
            kb_options = "grp:ctrl_space_toggle, compose:rctrl";
          }

          {
            name = "by-tech-air75-2";
            kb_options = "grp:ctrl_space_toggle, compose:rctrl";
          }

          {
            name = "kinesis-corporation-adv360-pro-keyboard";
            kb_options = "grp:alt_space_toggle, compose:rctrl";
          }

          {
            name = "adv360-pro-keyboard";
            kb_options = "grp:alt_space_toggle, compose:rctrl";
          }
        ];
      }
      // windowRules
      // keyBinds;
  };

  xdg = {
    mime.enable = true;
    # portal = {
    #   enable = true;
    #   extraPortals = [
    #     pkgs.xdg-desktop-portal-hyprland
    #     pkgs.xdg-desktop-portal-gtk
    #   ];
    #   xdgOpenUsePortal = true;
    #   config.common.default = "*";
    # };
  };

  home.sessionVariables = {
    HYPRCURSOR_THEME = "catppuccin-mocha-dark-cursors";
    HYPRCURSOR_SIZE = "24";
    ASAN_OPTIONS = "log_path=~/asan.log";
    MOZ_ENABLE_WAYLAND = 1;
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
    QT_QPA_PLATFORM = "wayland;xcb";
    GDK_BACKEND = "wayland,x11";
    CLUTTER_BACKEND = "wayland";
    SDL_VIDEODRIVER = "wayland";
    XCURSOR_SIZE = "24";
    GDK_SCALE = 1;
  };

  home.file = {
    "${config.xdg.configHome}/hypr/exec.conf" = {
      text = ''
        exec-once = ${config.programs.ags.finalPackage}/bin/ags
        exec-once = start_static_wallpaper ${wallpaperPath}
        # exec-once = start_video_wallpaper
        exec-once = ${pkgs.sox}/bin/play ${startupSound}
        exec-once = ${autoStart}
      '';
    };
  };
}
