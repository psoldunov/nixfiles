{
  config,
  libs,
  pkgs,
  ...
}: let
  hyprlockBin = "${pkgs.hyprlock}/bin/hyprlock";
  hyprctlBin = "${pkgs.hyprland}/bin/hyprctl";
in {
  programs.hyprlock = {
    enable = true;
    settings = {
      source = "${config.xdg.configHome}/hypr/mocha.conf";

      "$accent" = "$peach";
      "$accentAlpha" = "$peachAlpha";
      "$font" = "SFMono Nerd Font";

      # GENERAL
      general = {
        disable_loading_bar = true;
        hide_cursor = true;
      };

      # BACKGROUND
      background = [
        {
          path = "/usr/share/backgrounds/user/lock_background.png";
          blur_passes = 0;
          color = "rgba(28, 33, 43, 1)";
        }
      ];

      # TIME
      label = [
        {
          text = ''cmd[update:30000] echo "$(date +"%R")"'';
          color = "$text";
          font_size = 90;
          font_family = "$font";
          position = "-30, 0";
          halign = "right";
          valign = "top";
        }
        # DATE
        {
          text = ''cmd[update:43200000] echo "$(date +"%A, %d %B %Y")"'';
          color = "$text";
          font_size = 25;
          font_family = "$font";
          position = "-30, -150";
          halign = "right";
          valign = "top";
        }
      ];

      # USER AVATAR

      image = {
        path = "~/.face";
        size = 100;
        border_color = "$accent";
        position = "0, 75";
        halign = "center";
        valign = "center";
      };

      # INPUT FIELD
      input-field = {
        size = "300, 60";
        outline_thickness = 4;
        dots_size = 0.2;
        dots_spacing = 0.2;
        dots_center = true;
        outer_color = "$accent";
        inner_color = "$surface0";
        font_color = "$text";
        fade_on_empty = false;
        placeholder_text = ''<span foreground="##$textAlpha"><i>󰌾 Logged in as </i><span foreground="##$accentAlpha">$USER</span></span>'';
        hide_input = false;
        check_color = "$accent";
        fail_color = "$red";
        fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
        capslock_color = "$yellow";
        position = "0, -35";
        halign = "center";
        valign = "center";
      };
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pgrep hyprlock || idle_check || ${hyprlockBin}";
        unlock_cmd = "pkill -USR1 ${hyprlockBin}";
        before_sleep_cmd = "systemctl stop ollama.service && loginctl lock-session";
        after_sleep_cmd = "${hyprctlBin} dispatch dpms on && systemctl start ollama.service";
        ignore_dbus_inhibit = false;
        ignore_systemd_inhibit = false;
      };
      listener = [
        {
          timeout = 600;
          on-timeout = "idle_check || ${hyprctlBin} dispatch dpms off";
          on-resume = "${hyprctlBin} dispatch dpms on";
        }
        {
          timeout = 1800;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 3600;
          on-timeout = "idle_check || systemctl suspend";
        }
      ];
    };
  };

  home.file."${config.xdg.configHome}/hypr/mocha.conf" = {
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
}
