{config, ...}: {
  services.syncthing = {
    enable = true;
    user = "psoldunov";
    group = "users";
    guiAddress = "0.0.0.0:8384";
    openDefaultPorts = true;
    dataDir = "/RAID/apps/syncthing"; # Default folder for new synced folders
    settings.gui = {
      user = "psoldunov";
      password = "fbw7PAB8vej1zah!vjq";
    };
    settings = {
      options = {
        relaysEnabled = true;
        urAccepted = -1;
      };
      folders = {
        "Sync Folder" = {
          id = "default";
          devices = ["Whopper" "BigMac" "SteamDeck" "Nugget"];
          path = config.services.syncthing.dataDir + "/Sync";
        };
        "Projects" = {
          id = "d4fu6-xzjhs";
          devices = ["Whopper" "BigMac"];
          path = config.services.syncthing.dataDir + "/Projects";
        };
        "Emulation" = {
          id = "ycvsf-athpn";
          devices = ["SteamDeck"];
          path = "/mnt/Games/Emulation";
        };
        "Alan Wake 2" = {
          id = "nscmc-kuqck";
          devices = ["Whopper" "Nugget"];
          path = config.services.syncthing.dataDir + "/Alan Wake 2";
        };
        "Cat Quest II Save" = {
          id = "7vrlt-rxvca";
          devices = ["Whopper" "SteamDeck" "Nugget"];
          path = config.services.syncthing.dataDir + "/Cat Quest II Save";
        };
        "Crysis Saves" = {
          id = "q9cps-rcz9r";
          devices = ["Whopper" "SteamDeck" "Nugget"];
          path = config.services.syncthing.dataDir + "/Crysis Saves";
        };
        "Crysis 2 Saves" = {
          id = "pxfk2-zu55e";
          devices = ["Whopper" "SteamDeck" "Nugget"];
          path = config.services.syncthing.dataDir + "/Crysis 2 Saves";
        };
        "Crysis 3 Saves" = {
          id = "kegzx-cotaf";
          devices = ["Whopper" "SteamDeck" "Nugget"];
          path = config.services.syncthing.dataDir + "/Crysis 3 Saves";
        };
        "Just Cause 3 Saves" = {
          id = "r6u9d-cf4qv";
          devices = ["SteamDeck" "Nugget"];
          path = config.services.syncthing.dataDir + "/Just Cause 3 Saves";
        };
        "Silent Hill 2 Save" = {
          id = "utamf-amgzp";
          devices = ["Whopper" "SteamDeck" "Nugget"];
          path = config.services.syncthing.dataDir + "/Silent Hill 2 Save";
        };
        "Silent Hill 3 Save" = {
          id = "xanlu-cbnpg";
          devices = ["Whopper" "SteamDeck" "Nugget"];
          path = config.services.syncthing.dataDir + "/Silent Hill 3 Save";
        };
      };
      devices = {
        Whopper = {
          id = "UFUVKM7-NLI6ZPN-NS7O54P-ZLWSSS2-J67SCZ3-REND2NA-EGJRE3A-JL5MSQQ";
        };
        BigMac = {
          id = "K6FXVJ7-VBAQ7NX-B7H3YYE-O72Q4LR-ZE33TZQ-4EFBCR2-ZFNT5IB-FQILFQM";
        };
        SteamDeck = {
          id = "JOW45A7-VRICSJU-M534XZG-BSAECPK-J5QLLRK-L5GHGZT-RUZUTEL-NGQEKAF";
        };
        Nugget = {
          id = "3RQRTBJ-74IYA2U-G25MISG-SDQHU7F-WD7HHQB-FQ7PWOL-DU2EFWV-YPKWIAR";
        };
      };
    };
    overrideFolders = false;
    overrideDevices = false;
  };
}
