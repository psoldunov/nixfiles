{
  config,
  inputs,
  pkgs,
  ...
}: {
  wayland.windowManager.river = {
    enable = true;
    systemd.enable = true;
    xwayland.enable = true;
  };
}
