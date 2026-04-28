{
  pkgs,
  inputs,
  hostConfig,
  ...
}: let
  agsPkgs = inputs.ags.packages.${pkgs.stdenv.hostPlatform.system};
in {
  programs.ags = {
    enable = hostConfig.enableHyprland;

    configDir = ./ags;

    extraPackages = [
      agsPkgs.hyprland
      agsPkgs.wireplumber
      agsPkgs.mpris
      agsPkgs.tray
      agsPkgs.bluetooth
      agsPkgs.network

      pkgs.gtksourceview
      pkgs.accountsservice
      pkgs.gnome-bluetooth
      pkgs.dart-sass
    ];
  };
}
