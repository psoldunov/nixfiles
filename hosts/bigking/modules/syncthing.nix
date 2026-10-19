# The Emulation folder, shared with the Steam Deck straight from the Games
# share (lib/syncthing.nix). BigKing keeps no other folder.
#
# BigKing's device ID comes from the certificate generated on 2026-10-19
# with `syncthing generate` into ~/.config/syncthing; a reinstall makes a new
# one, which then goes into lib/syncthing.nix.
#
# No guiPasswordFile: BigKing keeps no sops secrets. The GUI listens on
# localhost only; reach it with `ssh -L 8384:localhost:8384 bigking`.
{...}: let
  syncthing = import ../../../lib/syncthing.nix;
in {
  services.syncthing = {
    enable = true;
    user = "psoldunov";
    # The group of everything psoldunov owns on /volume1.
    group = "users";
    dataDir = "/home/psoldunov";
    configDir = "/home/psoldunov/.config/syncthing";
    # TCP/UDP 22000 for sync, UDP 21027 for LAN discovery.
    openDefaultPorts = true;
    settings = {
      options = {
        urAccepted = -1;
        relaysEnabled = true;
      };
      devices = syncthing.devicesFor "BigKing";
      folders = syncthing.foldersFor "BigKing" {
        Emulation = "/volume1/Games/Emulation";
      };
    };
    overrideFolders = true;
    overrideDevices = true;
  };

  # Nothing may be served from an empty /volume1 if the array is missing.
  systemd.services.syncthing.unitConfig.RequiresMountsFor = ["/volume1"];
}
