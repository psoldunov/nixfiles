{
  globalSettings,
  lib,
  ...
}: {
  services.mako = {
    enable = globalSettings.enableHyprland;
    settings = lib.mkForce {
      defaultTimeout = 5000;
    };
    extraConfig = lib.mkForce null;
  };
}
