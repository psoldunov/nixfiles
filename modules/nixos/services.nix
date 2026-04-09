{
  config,
  pkgs,
  hostConfig,
  ...
}: {
  services.rpcbind.enable = true;
  services.upower.enable = true;
  services.fstrim.enable = true;
  services.fwupd.enable = true;
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

  # Udev for Apple Superdrive
  services.udev = {
    packages = [
      pkgs.yubikey-personalization
    ];
    extraRules = ''
      ACTION=="add", ATTRS{idProduct}=="1500", ATTRS{idVendor}=="05ac", DRIVERS=="usb", RUN+="${pkgs.sg3_utils}/bin/sg_raw %r/sr%n EA 00 00 00 00 00 01"
    '';
  };

  # Printing
  services.printing = {
    enable = true;
    cups-pdf.enable = true;
    drivers = with pkgs; [hplipWithPlugin];
  };

  # Ollama (native; containerized variant lives in ./virtualisation.nix)
  services.ollama = {
    enable = !hostConfig.ollamaDocker;
    package = pkgs.ollama-rocm;
    rocmOverrideGfx = "11.0.0";
    openFirewall = true;
    environmentVariables = {
      OLLAMA_ORIGINS = "app://obsidian.md*";
      OLLAMA_GPU_OVERHEAD = "2147483648";
    };
    loadModels = [
      "deepseek-coder-v2:16b-lite-base-q4_K_M"
      "mxbai-embed-large:latest"
      "codestral:latest"
      "llama3.2:latest"
      "nomic-embed-text:latest"
    ];
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
    # NOTE: the previous cleartext password value is still in git
    # history. Rotate it at the Syncthing UI after activation.
    guiPasswordFile = config.sops.secrets.SYNCTHING_GUI_PASSWORD.path;
    settings.gui = {
      user = "psoldunov";
    };
    settings.options = {
      urAccepted = -1;
      relaysEnabled = true;
    };
    overrideFolders = false;
    overrideDevices = false;
  };
}
