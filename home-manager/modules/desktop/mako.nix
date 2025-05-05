{
  globalSettings,
  lib,
  ...
}: {
  catppuccin.mako.enable = false;

  services.mako = {
    enable = true;
    settings = lib.mkForce {
      defaultTimeout = 5000;
    };
  };
}
