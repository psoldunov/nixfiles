{pkgs, globalSettings, ...}: {
  programs.ags = {
    enable = globalSettings.enableHyprland;

    configDir = ./ags;

    extraPackages = with pkgs; [
      gtksourceview
      webkitgtk
      accountsservice
      gnome-bluetooth
    ];
  };
}
