{
  pkgs,
  hostConfig,
  ...
}: {
  programs.ags = {
    enable = hostConfig.enableHyprland;

    configDir = ./ags;

    extraPackages = with pkgs; [
      gtksourceview
      accountsservice
      gnome-bluetooth
    ];
  };
}
