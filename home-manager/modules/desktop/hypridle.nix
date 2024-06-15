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
      background = {
        path = "/usr/share/backgrounds/user/lock_background.png";
      };

      input-field = {
        size = "200, 50";
        outline_thickness = "3";
        dots_size = "0.33"; # Scale of input-field height, 0.2 - 0.8
        dots_spacing = "0.15"; # Scale of dots' absolute size, 0.0 - 1.0
        dots_center = false;
        dots_rounding = "-1"; # -1 default circle, -2 follow input-field rounding
        outer_color = "rgb(151515)";
        inner_color = "rgb(200, 200, 200)";
        font_color = "rgb(10, 10, 10)";
        fade_on_empty = false;
        fade_timeout = "1000"; # Milliseconds before fade_on_empty is triggered.
        placeholder_text = "<i>Input Password...</i>"; # Text rendered in the input box when it's empty.
        hide_input = false;
        rounding = "-1"; # -1 means complete rounding (circle/oval)
        check_color = "rgb(204, 136, 34)";
        fail_color = "rgb(204, 34, 34)"; # if authentication failed, changes outer_color and fail message color
        fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>"; # can be set to empty
        fail_transition = "300"; # transition time in ms between normal outer_color and fail_color
        capslock_color = "-1";
        numlock_color = "-1";
        bothlock_color = "-1"; # when both locks are active. -1 means don't change outer color (same for above)
        invert_numlock = false; # change color if numlock is off
        swap_font_color = false; # see below
        position = "0, -20";
        halign = "center";
        valign = "center";
      };

      label = {
        text = "Hi there, $USER";
        color = "rgba(0, 0, 0, 1.0)";
        font_size = "25";
        font_family = "JetBrainsMono Nerd Font";
        position = "0, 80";
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
      };
      listener = [
        {
          timeout = 600;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 660;
          on-timeout = "idle_check || ${hyprctlBin} dispatch dpms off";
          on-resume = "${hyprctlBin} dispatch dpms on";
        }
        {
          timeout = 3600;
          on-timeout = "idle_check || systemctl suspend";
        }
      ];
    };
  };
}
