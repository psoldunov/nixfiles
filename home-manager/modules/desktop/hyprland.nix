{
  config,
  libs,
  pkgs,
  ...
}: let
  wallpaperPath = "${config.home.homeDirectory}/Pictures/Wallpapers/porsche-uw.jpg";
  windowRules = import ./hypr-modules/windowrules.nix;
  keyBinds = import ./hypr-modules/keybinds.nix {
    inherit config;
    inherit pkgs;
  };

  startupSound = ./assets/startup.wav;

  autoStart = pkgs.writeShellScript "autostart_applications" ''
    autostart_commands="
      ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
      ${pkgs.ydotool}/bin/ydotoold
      ${pkgs.wl-clipboard}/bin/wl-paste --type text --watch cliphist store
      ${pkgs.wl-clipboard}/bin/wl-paste --type image --watch cliphist store
      ${pkgs.nextcloud-client}/bin/nextcloud-client --background
      ${pkgs.solaar}/bin/solaar -w hide
      ${pkgs.slack}/bin/slack -u
      ${pkgs.ferdium}/bin/ferdium
      ${pkgs.telegram-desktop}/bin/telegram-desktop -startintray
      # ${pkgs.bitwarden-desktop}/bin/bitwarden
      # ${pkgs.localsend}/bin/localsend_app --hidden
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
    XCURSOR_SIZE = "24";
    GDK_SCALE = 1;
  };

  home.file = {
    "${config.xdg.configHome}/hypr/exec.conf" = {
      text = ''
        exec-once = ${config.programs.ags.finalPackage}/bin/ags
        # exec-once = start_static_wallpaper ${wallpaperPath}
        exec-once = start_video_wallpaper
        #exec-once = ${pkgs.sox}/bin/play ${config.xdg.configHome}/startup-sounds/current.wav
        exec-once = ${pkgs.sox}/bin/play ${startupSound}
        exec-once = ${autoStart}
      '';
    };
  };

  home.file = {
    "${config.xdg.configHome}/hypr/mocha.conf" = {
      text = ''
        $rosewater = rgb(f5e0dc)
        $rosewaterAlpha = f5e0dc

        $flamingo = rgb(f2cdcd)
        $flamingoAlpha = f2cdcd

        $pink = rgb(f5c2e7)
        $pinkAlpha = f5c2e7

        $mauve = rgb(cba6f7)
        $mauveAlpha = cba6f7

        $red = rgb(f38ba8)
        $redAlpha = f38ba8

        $maroon = rgb(eba0ac)
        $maroonAlpha = eba0ac

        $peach = rgb(fab387)
        $peachAlpha = fab387

        $yellow = rgb(f9e2af)
        $yellowAlpha = f9e2af

        $green = rgb(a6e3a1)
        $greenAlpha = a6e3a1

        $teal = rgb(94e2d5)
        $tealAlpha = 94e2d5

        $sky = rgb(89dceb)
        $skyAlpha = 89dceb

        $sapphire = rgb(74c7ec)
        $sapphireAlpha = 74c7ec

        $blue = rgb(89b4fa)
        $blueAlpha = 89b4fa

        $lavender = rgb(b4befe)
        $lavenderAlpha = b4befe

        $text = rgb(cdd6f4)
        $textAlpha = cdd6f4

        $subtext1 = rgb(bac2de)
        $subtext1Alpha = bac2de

        $subtext0 = rgb(a6adc8)
        $subtext0Alpha = a6adc8

        $overlay2 = rgb(9399b2)
        $overlay2Alpha = 9399b2

        $overlay1 = rgb(7f849c)
        $overlay1Alpha = 7f849c

        $overlay0 = rgb(6c7086)
        $overlay0Alpha = 6c7086

        $surface2 = rgb(585b70)
        $surface2Alpha = 585b70

        $surface1 = rgb(45475a)
        $surface1Alpha = 45475a

        $surface0 = rgb(313244)
        $surface0Alpha = 313244

        $base = rgb(1e1e2e)
        $baseAlpha = 1e1e2e

        $mantle = rgb(181825)
        $mantleAlpha = 181825

        $crust = rgb(11111b)
        $crustAlpha = 11111b
      '';
    };
  };
}
