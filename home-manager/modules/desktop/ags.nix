{
  pkgs,
  globalSettings,
  ...
}: {
  programs.ags = {
    enable = globalSettings.enableHyprland;

    configDir = ./ags;

    extraPackages = with pkgs; [
      gtksourceview
      accountsservice
      gnome-bluetooth
    ];
  };
}
