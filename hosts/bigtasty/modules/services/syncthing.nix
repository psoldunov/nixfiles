{config, ...}: {
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
          devices = ["Whopper" "BigMac" "SteamDeck"];
          path = config.services.syncthing.dataDir + "/Sync";
        };
        Obsidian = {
          id = "Obsidian";
          devices = ["Whopper" "BigMac" "SteamDeck"];
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
        SteamDeck = {
          id = "JOW45A7-VRICSJU-M534XZG-BSAECPK-J5QLLRK-L5GHGZT-RUZUTEL-NGQEKAF";
        };
      };
    };
    overrideFolders = true;
    overrideDevices = true;
  };
}
