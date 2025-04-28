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
}
