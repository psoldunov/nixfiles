{
  config,
  lib,
  globalSettings,
  ...
}: {
  programs.pywal.enable = globalSettings.enableHyprland;

  home.file = lib.mkIf globalSettings.enableHyprland {
    "${config.xdg.configHome}/wal/templates/colors-hyprland.conf" = {
      text = ''
        $background = rgb({background.strip})
        $foreground = rgb({foreground.strip})
        $color0 = rgb({color0.strip})
        $color1 = rgb({color1.strip})
        $color2 = rgb({color2.strip})
        $color3 = rgb({color3.strip})
        $color4 = rgb({color4.strip})
        $color5 = rgb({color5.strip})
        $color6 = rgb({color6.strip})
        $color7 = rgb({color7.strip})
        $color8 = rgb({color8.strip})
        $color9 = rgb({color9.strip})
        $color10 = rgb({color10.strip})
        $color11 = rgb({color11.strip})
        $color12 = rgb({color12.strip})
        $color13 = rgb({color13.strip})
        $color14 = rgb({color14.strip})
        $color15 = rgb({color15.strip})
      '';
    };
    "${config.xdg.configHome}/wal/templates/colors-waybar.conf" = {
      text = ''
        @define-color foreground {foreground};
        @define-color background {background};
        @define-color cursor {cursor};

        @define-color color0 {color0};
        @define-color color1 {color1};
        @define-color color2 {color2};
        @define-color color3 {color3};
        @define-color color4 {color4};
        @define-color color5 {color5};
        @define-color color6 {color6};
        @define-color color7 {color7};
        @define-color color8 {color8};
        @define-color color9 {color9};
        @define-color color10 {color10};
        @define-color color11 {color11};
        @define-color color12 {color12};
        @define-color color13 {color13};
        @define-color color14 {color14};
        @define-color color15 {color15};
      '';
    };
    "${config.xdg.configHome}/wal/templates/colors-wlogout.conf" = {
      text = ''
        @define-color foreground {foreground};
        @define-color background {background};
        @define-color cursor {cursor};

        @define-color color0 {color0};
        @define-color color1 {color1};
        @define-color color2 {color2};
        @define-color color3 {color3};
        @define-color color4 {color4};
        @define-color color5 {color5};
        @define-color color6 {color6};
        @define-color color7 {color7};
        @define-color color8 {color8};
        @define-color color9 {color9};
        @define-color color10 {color10};
        @define-color color11 {color11};
        @define-color color12 {color12};
        @define-color color13 {color13};
        @define-color color14 {color14};
        @define-color color15 {color15};
      '';
    };
    "${config.xdg.configHome}/wal/templates/colors-zellij.kdl" = {
      text = ''
        themes {{
          pywal {{
            fg "{foreground}"
            bg "{background}"
            black "{color0}"
            red "{color1}"
            green "{color2}"
            yellow "{color3}"
            blue "{color4}"
            magenta "{color5}"
            cyan "{color6}"
            white "{color7}"
            orange "{color8}"
          }}
        }}
      '';
    };
  };
}
