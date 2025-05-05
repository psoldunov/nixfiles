{
  globalSettings,
  lib,
  ...
}: {
  catppuccin.mako.enable = false;

  services.mako = {
    enable = true;
    settings = {
      defaultTimeout = 5000;
    };
  };
}
