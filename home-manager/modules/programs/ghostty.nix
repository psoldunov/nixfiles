{config, ...}: {
  home.file."${config.xdg.configHome}/ghostty/config" = {
    text = ''
      window-decoration = false
      background-opacity = 0.7
      font-family = "JetBrainsMono Nerd Font"
      font-size = 12.5
      font-style = bold

      window-padding-x = 8,4
      window-padding-y = 8

      background = "#151216"
      foreground = "#c6c0c1"
      cursor-color = "#c6c0c1"

      keybind = ctrl+c=copy_to_clipboard
      keybind = ctrl+v=paste_from_clipboard
      keybind = super+c=text:\x03
      keybind = super+v=text:\x16
      keybind = super+x=text:\x18
      keybind = super+z=text:\x1a
      keybind = super+d=text:\x04
    '';
  };
}
