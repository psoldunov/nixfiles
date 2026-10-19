# The Sync folder, shared with BigTasty and Whopper, which list ShackStack
# back (hosts/bigtasty/modules/services/syncthing.nix,
# hosts/whopper/modules/services.nix). The Macs and the Steam Deck get its
# changes through BigTasty. ShackStack's device ID comes from the
# certificate Syncthing made on first start in ~/.config/syncthing; a
# reinstall makes a new one, which the other two then need.
#
# No guiPasswordFile: that would need the sops age key, and ShackStack keeps
# none. The GUI listens on localhost only, and its password was set once by
# hand through the REST API; Syncthing keeps it as a bcrypt hash in
# config.xml, which nothing here overwrites.
{...}: {
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
      devices = {
        BigTasty.id = "GJTMGVV-ZBUNMER-CJRQLQS-CYPIVBO-UDLPMIZ-UW76NMG-YKEBQWH-IIMH5AY";
        Whopper.id = "UFUVKM7-NLI6ZPN-NS7O54P-ZLWSSS2-J67SCZ3-REND2NA-EGJRE3A-JL5MSQQ";
      };
      folders.Sync = {
        id = "default";
        path = "/home/psoldunov/Sync";
        label = "Sync Folder";
        devices = ["BigTasty" "Whopper"];
      };
    };
    overrideFolders = true;
    overrideDevices = true;
  };
}
