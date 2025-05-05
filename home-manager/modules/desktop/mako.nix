{globalSettings, ...}: {
  services.mako = {
    enable = globalSettings.enableHyprland;
    settings = {
      defaultTimeout = 5000;
    };
  };
}
