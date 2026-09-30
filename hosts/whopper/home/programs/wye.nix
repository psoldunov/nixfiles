# Wye — browser picker that routes every link to the right browser, profile or
# app, from its own flake. Bump it with `nix flake update wye`.
#
# Installs the `git` channel, compiled from the locked master commit, rather
# than a tagged release. The module installs the package and the Plasma applet,
# links the D-Bus activation files, and runs `wye service` as the systemd user
# unit `wye.service` from login. The UI host `wye-ui` is bus-activated on first
# use.
#
# `settings` is left empty so ~/.config/wye/config.toml stays writable from
# Wye's Settings window. `defaultBrowser` is left off: Wye is made the http and
# https handler in hosts/whopper/mime-defaults.nix and in kdeglobals
# (desktop/plasma.nix) instead, so each list keeps a single source rather than
# two modules racing over the same keys.
#
# The tray applet still has to be shown once by hand: System Tray settings,
# Entries, set Wye to Shown.
{inputs, ...}: {
  imports = [
    inputs.wye.homeManagerModules.default
  ];

  programs.wye = {
    enable = true;
    channel = "git";
  };
}
