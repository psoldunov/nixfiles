{
  globalSettings,
  lib,
  ...
}: {
  cattppuccin.mako.enable = false;

  services.mako = {
    enable = globalSettings.enableHyprland;
    settings = lib.mkForce {
      defaultTimeout = 5000;
    };
  };
}
