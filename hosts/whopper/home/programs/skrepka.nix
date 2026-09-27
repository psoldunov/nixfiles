# Skrepka — clipboard history with LAN sync, from its own flake.
#
# The module links the D-Bus activation file, the user unit, the launcher entry
# and the icons into the places a session reads regardless of Nix, so an
# upgrade is just a rebuild. The GNOME Shell extension is skipped: this host
# runs Plasma, where the daemon reads the clipboard directly.
#
# Plasma's own Klipper still records clipboard history alongside it. Turn
# Klipper off in System Settings if two histories are one too many — Plasma
# exposes no declarative switch for it.
{inputs, ...}: {
  imports = [
    inputs.skrepka.homeManagerModules.default
  ];

  programs.skrepka = {
    enable = true;
    autostart = true;
  };
}
