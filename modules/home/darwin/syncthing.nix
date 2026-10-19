# Syncthing on the Macs, run by launchd from home-manager's module. The
# devices and folders come from lib/syncthing.nix, under the host name
# nix-darwin sets (hosts/<host>/modules), which is also the device's name
# there. The config, keys and database stay in
# ~/Library/Application Support/Syncthing, where the old Homebrew service
# kept them, so each Mac keeps its device ID. The GUI is on 127.0.0.1:8384.
{
  config,
  osConfig,
  ...
}: let
  syncthing = import ../../../lib/syncthing.nix;
  device = osConfig.networking.hostName;
  home = config.home.homeDirectory;
in {
  services.syncthing = {
    enable = true;
    settings = {
      options = {
        urAccepted = -1;
        relaysEnabled = true;
      };
      devices = syncthing.devicesFor device;
      folders = syncthing.foldersFor device {
        Sync = "${home}/Sync";
        Obsidian = "${home}/Documents/Obsidian";
      };
    };
    overrideFolders = true;
    overrideDevices = true;
  };

  # The module installs only the man page; this puts the `syncthing` CLI
  # back on PATH, as the Homebrew formula did.
  home.packages = [config.services.syncthing.package];
}
