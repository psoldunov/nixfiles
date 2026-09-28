# Skrepka — clipboard history with LAN sync, from its own flake.
#
# Installs the `master` variant, compiled from the locked master commit, rather
# than the release tarball. Bump it with `nix flake update skrepka`. The build
# runs bubblewrap inside the Nix sandbox, so it needs unprivileged user
# namespaces, which NixOS allows by default.
#
# The module links the D-Bus activation file, the user unit, the launcher entry
# and the icons into the places a session reads regardless of Nix, so an
# upgrade is just a rebuild. The GNOME Shell extension is skipped: this host
# runs Plasma, where the daemon reads the clipboard directly.
#
# Plasma's own Klipper still records clipboard history alongside it. Turn
# Klipper off in System Settings if two histories are one too many — Plasma
# exposes no declarative switch for it.
{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.skrepka.homeManagerModules.default
  ];

  programs.skrepka = {
    enable = true;
    package = inputs.skrepka.packages.${pkgs.stdenv.hostPlatform.system}.master;
    autostart = true;
  };
}
