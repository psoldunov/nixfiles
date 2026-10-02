# Figma Linux Next — Electron wrapper for the Figma web app, from its own
# flake. The flake repackages the prebuilt release zip and pins the version
# itself, so bump it with `nix flake update figma-linux-next`.
#
# The upstream NixOS module is not used: it only installs the package
# system-wide and sets the figma:// handler in /etc/xdg/mimeapps.list. The
# package goes in here per user like every other GUI app, and the handler lives
# in hosts/whopper/mime-defaults.nix, which also feeds ~/.config/mimeapps.list.
# "Log in with browser" needs that handler to come back to the app.
{
  inputs,
  pkgs,
  ...
}: {
  home.packages = [
    inputs.figma-linux-next.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
