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
      size = 12.5;
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
