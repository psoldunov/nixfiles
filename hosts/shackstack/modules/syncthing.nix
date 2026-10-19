# The Sync folder, shared directly with every other Syncthing host
# (lib/syncthing.nix). The Alan Wake saves go to Whopper and BigTasty
# (modules/nixos/game-saves.nix). ShackStack's device ID comes from the
# certificate Syncthing made on first start in ~/.config/syncthing; a
# reinstall makes a new one, which then goes into lib/syncthing.nix.
#
# No guiPasswordFile: that would need the sops age key, and ShackStack keeps
# none. The GUI listens on localhost only, and its password was set once by
# hand through the REST API; Syncthing keeps it as a bcrypt hash in
# config.xml, which nothing here overwrites.
{...}: let
  syncthing = import ../../../lib/syncthing.nix;
in {
  imports = [../../../modules/nixos/game-saves.nix];

  gameSaves = {
    heroicPrefixes = "/home/psoldunov/Games/Heroic/Prefixes";
    devices = ["Whopper" "BigTasty"];
  };

  services.syncthing = {
    enable = true;
    user = "psoldunov";
    dataDir = "/home/psoldunov";
    configDir = "/home/psoldunov/.config/syncthing";
    # TCP/UDP 22000 for sync, UDP 21027 for LAN discovery.
    openDefaultPorts = true;
    settings = {
      gui.user = "psoldunov";
      options = {
        urAccepted = -1;
        relaysEnabled = true;
      };
      devices = syncthing.devicesFor "ShackStack";
      folders = syncthing.foldersFor "ShackStack" {
        Sync = "/home/psoldunov/Sync";
      };
    };
    overrideFolders = true;
    overrideDevices = true;
  };
}
