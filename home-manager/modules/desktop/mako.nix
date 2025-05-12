{
  globalSettings,
  lib,
  ...
}: {
  # catppuccin.mako.enable = false;

  services.mako = {
    enable = true;
    settings = {
      "default-timeout" = 5000;
    };
  };
}
