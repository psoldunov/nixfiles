{
  config,
  libs,
  pkgs,
  ...
}: {
  programs.kitty = {
    enable = true;
    shellIntegration.enableFishIntegration = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 10.5;
    };
    settings = {
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
      allow_remote_control = "yes";
      background_opacity = "0.7";
      mouse_hide_wait = "3.0";
      window_padding_width = 4;
      confirm_os_window_close = 0;
    };
    # extraConfig = ''
    #   # vim:ft=kitty

    #   ## name:     Catppuccin Kitty Mocha
    #   ## author:   Catppuccin Org
    #   ## license:  MIT
    #   ## upstream: https://github.com/catppuccin/kitty/blob/main/themes/mocha.conf
    #   ## blurb:    Soothing pastel theme for the high-spirited!

    #   # The basic colors
    #   foreground              #CDD6F4
    #   background              #1E1E2E
    #   selection_foreground    #1E1E2E
    #   selection_background    #F5E0DC

    #   # Cursor colors
    #   cursor                  #F5E0DC
    #   cursor_text_color       #1E1E2E

    #   # URL underline color when hovering with mouse
    #   url_color               #F5E0DC

    #   # Kitty window border colors
    #   active_border_color     #B4BEFE
    #   inactive_border_color   #6C7086
    #   bell_border_color       #F9E2AF

    #   # OS Window titlebar colors
    #   wayland_titlebar_color  #1E1E2E
    #   macos_titlebar_color    #1E1E2E

    #   # Tab bar colors
    #   active_tab_foreground   #11111B
    #   active_tab_background   #CBA6F7
    #   inactive_tab_foreground #CDD6F4
    #   inactive_tab_background #181825
    #   tab_bar_background      #11111B

    #   # Colors for marks (marked text in the terminal)
    #   mark1_foreground #1E1E2E
    #   mark1_background #B4BEFE
    #   mark2_foreground #1E1E2E
    #   mark2_background #CBA6F7
    #   mark3_foreground #1E1E2E
    #   mark3_background #74C7EC

    #   # The 16 terminal colors

    #   # black
    #   color0 #45475A
    #   color8 #585B70

    #   # red
    #   color1 #F38BA8
    #   color9 #F38BA8

    #   # green
    #   color2  #A6E3A1
    #   color10 #A6E3A1

    #   # yellow
    #   color3  #F9E2AF
    #   color11 #F9E2AF

    #   # blue
    #   color4  #89B4FA
    #   color12 #89B4FA

    #   # magenta
    #   color5  #F5C2E7
    #   color13 #F5C2E7

    #   # cyan
    #   color6  #94E2D5
    #   color14 #94E2D5

    #   # white
    #   color7  #BAC2DE
    #   color15 #A6ADC8

    #   tab_bar_min_tabs            1
    #   tab_bar_edge                bottom
    #   tab_bar_style               powerline
    #   tab_powerline_style         slanted
    #   tab_title_template          {title}{" :{}:".format(num_windows) if num_windows > 1 else ""}
    # '';
  };

  home.file."${config.xdg.configHome}/kitty/kitty-nuphy.conf" = {
    text = ''
      include ${config.xdg.configHome}/kitty/kitty.conf
      map ctrl+c copy_to_clipboard
      map ctrl+v paste_from_clipboard
      map super+c send_text normal,application \x03
      map super+v send_text normal,application \x16
      map super+x send_text normal,application \x18
      map super+z send_text normal,application \x1a
      map super+d send_text normal,application \x04
    '';
  };
}
