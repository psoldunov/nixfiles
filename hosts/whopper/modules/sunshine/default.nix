# Sunshine, the game stream host for Moonlight clients. It runs as a user
# service in the Plasma session and starts with it.
#
# Settings and apps are declared here, so the web UI at https://Whopper:47990
# cannot change them; it is still where clients are paired. Pairings live in
# ~/.config/sunshine/sunshine_state.json, outside the store.
#
# Capture is KMS, which needs CAP_SYS_ADMIN (`capSysAdmin` puts Sunshine
# behind a wrapper in /run/wrappers/bin that holds it) and is the only Linux
# capture method that streams HDR. Sunshine drops the capability right after
# startup, so apps it launches, Steam's bwrap among them, never inherit it.
# The RX 7900 XTX encodes through VA-API.
#
# Each stream switches the monitor to the client's resolution and back (see
# ./display.sh). The Steam Deck OLED's Moonlight asks for 1920x1200 at 90 fps,
# which renders sharper than the Deck's native 1280x800. DP-2 advertises
# 1920x1200 only at 60 and 144 Hz, so the 90 Hz mode is added in KWin as a
# custom mode.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.sunshine;

  webUsername = "psoldunov";

  display = pkgs.writeShellApplication {
    name = "sunshine-display";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.kdePackages.libkscreen];
    runtimeEnv.CUSTOM_MODES = "1920x1200@90";
    text = builtins.readFile ./display.sh;
  };

  # The same file the nixpkgs module renders from `settings`, so `--creds`
  # resolves the credentials file exactly as the running service does.
  configFile = (pkgs.formats.keyValue {}).generate "sunshine.conf" cfg.settings;

  # Writes the web UI login from sops before every start, which also undoes
  # any password change made in the web UI. `--creds` keeps the pairings
  # stored in the same file. Sunshine takes the password only as an argument,
  # so it shows in this short-lived process's command line.
  setWebCredentials = pkgs.writeShellApplication {
    name = "sunshine-web-credentials";
    text = ''
      password=$(<${config.sops.secrets.SUNSHINE_WEB_PASSWORD.path})
      exec ${lib.getExe cfg.package} ${configFile} --creds ${webUsername} "$password"
    '';
  };

  steam = lib.getExe config.programs.steam.package;
  setsid = "${pkgs.util-linux}/bin/setsid";
in {
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;

    settings = {
      sunshine_name = "Whopper";
      capture = "kms";
      encoder = "vaapi";
      # Sunshine splits commands on spaces and runs them without a shell.
      global_prep_cmd = builtins.toJSON [
        {
          do = "${lib.getExe display} do";
          undo = "${lib.getExe display} undo";
        }
      ];
    };

    applications.apps = [
      {
        name = "Desktop";
        image-path = "desktop.png";
      }
      # Steam is already running in the tray (see home/xdg/autostart.nix), so
      # these only switch the running client in and out of Big Picture.
      {
        name = "Steam Big Picture";
        image-path = "steam.png";
        detached = ["${setsid} ${steam} steam://open/bigpicture"];
        prep-cmd = [
          {
            do = "";
            undo = "${setsid} ${steam} steam://close/bigpicture";
          }
        ];
      }
    ];
  };

  systemd.user.services.sunshine.serviceConfig.ExecStartPre = lib.getExe setWebCredentials;

  # For `sunshine-display undo` by hand, after a stream that ended without one.
  environment.systemPackages = [display];
}
