{config, ...}: let
  syncthing = import ../../../../lib/syncthing.nix;
in {
  imports = [../../../../modules/nixos/game-saves.nix];

  # The Alan Wake saves, as "<title> Saves" next to the other game saves
  # here, so Whopper and ShackStack trade them without being on together.
  # "Alan Wake 2 (2024 backup)" beside them is the copy the saves were
  # restored from on 2026-10-19; no folder uses it.
  gameSaves = {
    storageDir = config.services.syncthing.dataDir;
    devices = ["Whopper" "ShackStack"];
  };

  services.syncthing = {
    enable = true;
    user = "psoldunov";
    group = "users";
    guiAddress = "0.0.0.0:8384";
    openDefaultPorts = true;
    dataDir = "/RAID/apps/syncthing";
    guiPasswordFile = config.sops.secrets.SYNCTHING_GUI_PASSWORD.path;
    settings = {
      options = {
        relaysEnabled = true;
        urAccepted = -1;
      };
      # Device IDs and who shares what: lib/syncthing.nix.
      devices = syncthing.devicesFor "BigTasty";
      folders =
        syncthing.foldersFor "BigTasty" {
          Sync = config.services.syncthing.dataDir + "/Sync";
          Obsidian = config.services.syncthing.dataDir + "/Obsidian";
        }
        // {
          # The Steam Deck takes the Remastered saves, and only from here.
          # NixOS appends this to the devices game-saves.nix gives the folder.
          AlanWakeRemastered.devices = ["SteamDeck"];
        };
    };
    overrideFolders = true;
    overrideDevices = true;
  };
}
