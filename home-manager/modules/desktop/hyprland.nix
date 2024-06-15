{
  config,
  libs,
  pkgs,
  ...
}: let
  wallpaperPath = "${config.home.homeDirectory}/Pictures/Wallpapers/porsche.jpg";
  windowRules = import ./hypr-modules/windowrules.nix;
  keyBinds = import ./hypr-modules/keybinds.nix;

  autoStart = pkgs.writeShellScript "autostart_applications" ''
    autostart_commands="
      ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
      ${pkgs.ydotool}/bin/ydotoold
      ${pkgs.solaar}/bin/solaar -w hide
      ${pkgs.wl-clipboard}/bin/wl-paste --type text --watch cliphist store
      ${pkgs.wl-clipboard}/bin/wl-paste --type image --watch cliphist store
      ${pkgs.xwaylandvideobridge}/bin/xwaylandvideobridge
      ${pkgs.slack}/bin/slack -u
      ${pkgs.ferdium}/bin/ferdium
      ${pkgs.telegram-desktop}/bin/telegram-desktop -startintray
      ${pkgs.nextcloud-client}/bin/nextcloud-client --background
      1password --silent
      steam -silent
      vesktop --start-minimized
      systemctl --user restart blueman-applet
    "

    sleep 5

    echo "$autostart_commands" | while read -r cmd; do
      eval "$cmd &"
    done
  '';
in {
  services.blueman-applet.enable = true;
  services.mpris-proxy.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;
    systemd = {
      enable = true;
      enableXdgAutostart = true;
    };
    xwayland.enable = true;
    settings =
      {
        source = [
          "${config.xdg.configHome}/hypr/exec.conf"
          "${config.xdg.cacheHome}/wal/colors-hyprland.conf"
        ];
        monitor = "DP-1,preferred,auto,1";
        input = {
          kb_layout = "us,ru";
          kb_variant = ",mac";
          follow_mouse = true;
          mouse_refocus = false;
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
          border_size = 3;
          "col.active_border" = "$foreground";
          "col.inactive_border" = "$color11";
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
        master = {
          new_is_master = true;
        };
        debug = {
          overlay = "off";
        };
        misc = {
          focus_on_activate = true;
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          vrr = 0;
          allow_session_lock_restore = true;
        };
        device = [
          {
            name = "by-tech-air75";
            kb_options = "grp:ctrl_space_toggle, compose:rctrl";
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

  home.sessionVariables = {
    # GDK_SCALE = "1.1";
    # GDK_DPI_SCALE = "1.1";
    # QT_SCALE_FACTOR = "1.2";
    # QT_AUTO_SCREEN_SCALE_FACTOR = "0";
    GTK_THEME = "Catppuccin-Mocha-Standard-Blue-Dark";
    HYPRCURSOR_THEME = "catppuccin-mocha-dark-cursors";
    HYPRCURSOR_SIZE = "24";
    ASAN_OPTIONS = "log_path=~/asan.log";
    CLUTTER_BACKEND = "wayland";
    MOZ_ENABLE_WAYLAND = 1;
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
  };

  home.file = {
    "${config.xdg.configHome}/hypr/exec.conf" = {
      text = ''
        exec-once = start_static_wallpaper ${wallpaperPath}
        exec-once = ${autoStart}
      '';
    };
  };
}
