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
}
