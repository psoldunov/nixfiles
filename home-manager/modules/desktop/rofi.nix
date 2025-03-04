{
  config,
  pkgs,
  globalSettings,
  ...
}: let
  inherit (config.lib.formats.rasi) mkLiteral;
in {
  programs.rofi = {
    enable = globalSettings.enableHyprland;
    package = pkgs.rofi-wayland.override {
      plugins = with pkgs; [
        (rofi-calc.override {
          rofi-unwrapped = rofi-wayland-unwrapped;
        })
        (rofi-top.override {
          rofi-unwrapped = rofi-wayland-unwrapped;
        })
      ];
    };
    font = "JetBrainsMono Nerd Font 11";
    extraConfig = {
      display-drun = "Applications";
      display-window = "Windows";
      display-combi = "Run";
      drun-display-format = "{name}";
      modi = "window,run,drun";
      combi-modi = "drun,window,run";
      show-icons = true;
    };
    pass = {
      enable = true;
      package = pkgs.rofi-pass-wayland;
    };
    theme = {
      "#window" = {
        border-radius = mkLiteral "8px";
        width = mkLiteral "700px";
        border = mkLiteral "1px solid";
        border-color = mkLiteral "@foreground";
      };

      "#element" = {
        padding = mkLiteral "6px";
      };

      "#element-icon" = {
        background-color = mkLiteral "inherit";
        margin = mkLiteral "0 6px 0 0";
      };

      "#element-text.selected" = {
        background-color = mkLiteral "inherit";
        text-color = mkLiteral "@background";
      };

      "#element" = {
        background-color = mkLiteral "red";
      };

      "#element-text" = {
        text-color = mkLiteral "#ffffff";
      };
    };
  };
}
