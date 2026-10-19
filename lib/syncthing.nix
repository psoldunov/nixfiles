# Syncthing devices and the folders they share, for every host that runs
# Syncthing: BigTasty, Whopper and ShackStack through the NixOS module, and
# BigMac and MacFlurry through home-manager's
# (modules/home/darwin/syncthing.nix). The Steam Deck isn't managed here, so
# a new share or device has to be accepted on the Deck by hand.
#
# The hosts form a full mesh. Each one lists every other device and shares
# each folder it keeps with every other member of that folder, so changes go
# straight between any two hosts that are on at the same time instead of
# waiting for BigTasty. The Alan Wake saves are not in here; they have their
# own module (modules/nixos/game-saves.nix), which refers to these device
# names.
#
# A device ID comes from the certificate Syncthing makes on first start
# (cert.pem and key.pem in its config directory). Reinstalling without them
# makes a new ID, which then replaces the old one here.
#
#   services.syncthing.settings = {
#     devices = syncthing.devicesFor "BigTasty";
#     folders = syncthing.foldersFor "BigTasty" {Sync = "/RAID/apps/syncthing/Sync";};
#   };
let
  devices = {
    BigTasty = "GJTMGVV-ZBUNMER-CJRQLQS-CYPIVBO-UDLPMIZ-UW76NMG-YKEBQWH-IIMH5AY";
    Whopper = "UFUVKM7-NLI6ZPN-NS7O54P-ZLWSSS2-J67SCZ3-REND2NA-EGJRE3A-JL5MSQQ";
    ShackStack = "WBFYFYV-GNAXSFN-ASQBELJ-VM35BOL-YM4PXG7-OGU3RGF-R3ZUZLN-UZHD6Q2";
    BigMac = "SDLAT7V-MXGQHXG-W2QIP3S-OUS6232-LJ4QF36-IUR4QJ7-C32QKGO-BVJOXQS";
    MacFlurry = "KURK5RF-HZKBXEU-OBBUQ6E-D3PC723-I2ZPRII-54R5ENX-VMALIIA-WOII4QJ";
    SteamDeck = "JOW45A7-VRICSJU-M534XZG-BSAECPK-J5QLLRK-L5GHGZT-RUZUTEL-NGQEKAF";
  };

  # `members` is every device that keeps a copy, the host itself included.
  folders = {
    Sync = {
      id = "default";
      label = "Sync Folder";
      members = builtins.attrNames devices;
    };
    Obsidian = {
      id = "Obsidian";
      label = "Obsidian";
      members = ["BigTasty" "Whopper" "BigMac" "MacFlurry" "SteamDeck"];
    };
    Emulation = {
      id = "ycvsf-athpn";
      label = "Emulation";
      members = ["BigTasty" "Whopper" "SteamDeck"];
    };
  };

  knownDevice = self:
    if devices ? ${self}
    then self
    else throw "lib/syncthing.nix: no device named ${self}";

  folderFor = self: name: path: let
    folder = folders.${name} or (throw "lib/syncthing.nix: no folder named ${name}");
  in
    if builtins.elem self folder.members
    then {
      inherit (folder) id label;
      inherit path;
      devices = builtins.filter (device: device != self) folder.members;
    }
    else throw "lib/syncthing.nix: ${self} is not a member of ${name}";
in {
  inherit devices folders;

  # Every device except `self`, as services.syncthing.settings.devices.
  devicesFor = self:
    builtins.mapAttrs (_: id: {inherit id;})
    (builtins.removeAttrs devices [(knownDevice self)]);

  # The folders `self` keeps, as services.syncthing.settings.folders.
  # `paths` maps a folder name from `folders` to its local path.
  foldersFor = self: paths: builtins.mapAttrs (folderFor (knownDevice self)) paths;
}
