{config, ...}: {
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
      folders = {
        "Sync Folder" = {
          id = "default";
          devices = ["Whopper" "BigMac" "MacFlurry" "SteamDeck" "ShackStack"];
          path = config.services.syncthing.dataDir + "/Sync";
        };
        Obsidian = {
          id = "Obsidian";
          devices = ["Whopper" "BigMac" "MacFlurry" "SteamDeck"];
          path = config.services.syncthing.dataDir + "/Obsidian";
        };
        Emulation = {
          id = "ycvsf-athpn";
          devices = ["SteamDeck" "Whopper"];
          path = "/mnt/Games/Emulation";
        };
      };
      devices = {
        Whopper = {
          id = "UFUVKM7-NLI6ZPN-NS7O54P-ZLWSSS2-J67SCZ3-REND2NA-EGJRE3A-JL5MSQQ";
        };
        BigMac = {
          id = "SDLAT7V-MXGQHXG-W2QIP3S-OUS6232-LJ4QF36-IUR4QJ7-C32QKGO-BVJOXQS";
        };
        MacFlurry = {
          id = "KURK5RF-HZKBXEU-OBBUQ6E-D3PC723-I2ZPRII-54R5ENX-VMALIIA-WOII4QJ";
        };
        SteamDeck = {
          id = "JOW45A7-VRICSJU-M534XZG-BSAECPK-J5QLLRK-L5GHGZT-RUZUTEL-NGQEKAF";
        };
        # From hosts/shackstack/modules/syncthing.nix's first start.
        ShackStack = {
          id = "WBFYFYV-GNAXSFN-ASQBELJ-VM35BOL-YM4PXG7-OGU3RGF-R3ZUZLN-UZHD6Q2";
        };
      };
    };
    overrideFolders = true;
    overrideDevices = true;
  };
}
