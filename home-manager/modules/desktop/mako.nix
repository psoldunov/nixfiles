{globalSettings, ...}: {
  services.mako = {
    enable = globalSettings.enableHyprland;
    defaultTimeout = 5000;
  };
}
