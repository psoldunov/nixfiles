{
  config,
  pkgs,
  ...
}: let
  syncthing = import ../../../lib/syncthing.nix;
in {
  # services.fwupd lives in modules/nixos/hardware.nix.
  services.rpcbind.enable = true;
  services.upower.enable = true;
  services.fstrim.enable = true;
  services.usbmuxd.enable = true;
  services.locate.enable = true;
  services.ddccontrol.enable = true;
  services.vscode-server.enable = true;
  services.expressvpn.enable = true;

  # Audio
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    wireplumber.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    lowLatency = {
      enable = true;
    };
    # A dummy AVRCP player (off by default) makes AirPods send play/pause/skip
    # to the host; LibrePods' README asks for it.
    wireplumber.extraConfig."51-bluez-avrcp" = {
      "monitor.bluez.properties" = {
        "bluez5.dummy-avrcp-player" = true;
      };
    };
  };

  # Force DisplayPort link retrain after suspend
  systemd.services.dp-retrain = {
    description = "Force DisplayPort link retrain after suspend";
    wantedBy = ["suspend.target"];
    after = ["suspend.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        bash -c 'sleep 2 && for conn in /sys/class/drm/card*-DP-*; do \
          if [ -w "$conn/retrain" ]; then echo 1 > "$conn/retrain"; fi; \
        done'
      '';
    };
  };

  # Apple Superdrive udev rule lives in modules/nixos/hardware.nix.
  services.udev.packages = [pkgs.yubikey-personalization];

  # Printing
  services.printing = {
    enable = true;
    cups-pdf.enable = true;
    drivers = with pkgs; [hplipWithPlugin];
  };

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    ensureUsers = [
      {
        name = "psoldunov";
      }
    ];
    ensureDatabases = [
      "psoldunov"
    ];
  };

  services.cloudflared = {
    enable = false;
  };

  services.syncthing = {
    enable = true;
    user = "psoldunov";
    relay.enable = true;
    dataDir = "/home/psoldunov/";
    configDir = "/home/psoldunov/.config/syncthing";
    guiPasswordFile = config.sops.secrets.SYNCTHING_GUI_PASSWORD.path;
    settings.gui = {
      user = "psoldunov";
    };
    settings.options = {
      urAccepted = -1;
      relaysEnabled = true;
    };
    # Device IDs and who shares what: lib/syncthing.nix.
    settings.devices = syncthing.devicesFor "Whopper";
    settings.folders = syncthing.foldersFor "Whopper" {
      Obsidian = "/home/psoldunov/Documents/Obsidian";
      Sync = "/home/psoldunov/Sync";
    };
    overrideFolders = true;
    overrideDevices = true;
  };

  # The Alan Wake save folders, shared with ShackStack and BigTasty.
  gameSaves = {
    heroicPrefixes = "/SATA/Heroic/Prefixes";
    devices = ["ShackStack" "BigTasty"];
  };
}
