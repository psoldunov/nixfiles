# Desktop Mode on the TV, via plasma-manager: SteamOS's Vapor theme, 200%
# scale for the couch, no screen lock or idle sleep (Gaming Mode owns
# power), one panel with the way back to Gaming Mode on it, and Steam and
# 1Password in the tray.
#
# NOTE: because `panels` is defined here, plasma-manager owns the panel
# layout; edits in System Settings are reset on the next rebuild.
{
  lib,
  osConfig,
  pkgs,
  ...
}: let
  # Jovian's Steam always runs with -steamdeck -pipewire, as SteamOS's does.
  # Under Plasma, -pipewire has Steam ask the screencast portal for a screen
  # at every start, which is KDE's "Screen Sharing Requested" dialog each
  # time, with no way to allow it for good. Desktop Mode starts this copy
  # without the flag. Gaming Mode keeps it: gamescope serves the capture with
  # no prompt. Remote Play and game recording started from Desktop Mode lose
  # PipeWire capture. Jovian's wrapper is not overridable itself: it puts
  # the flags in nixpkgs' extraArgs, so that is what gets replaced.
  desktopSteam = osConfig.programs.steam.package.override {
    extraArgs = "-steamdeck";
  };
  desktopSteamExe = lib.getExe desktopSteam;

  # Steam's own launcher, every Exec line pointed at desktopSteam, so the
  # menu and steam:// links start that copy too. A user entry of the same
  # name hides the system one.
  desktopSteamEntry = pkgs.runCommand "steam.desktop" {} ''
    src=${desktopSteam}/share/applications/steam.desktop
    sed 's|^Exec=steam |Exec=${desktopSteamExe} |' "$src" > $out
    if grep -q '^Exec=steam' $out || ! grep -q '^Exec=${desktopSteamExe} ' $out; then
      echo "steam.desktop: Exec lines no longer start with 'steam '" >&2
      exit 1
    fi
  '';

  # Steam and 1Password start in the tray whenever Desktop Mode does, as on
  # Whopper (../../whopper/home/xdg/autostart.nix). The file names are the
  # ones the apps' own "start at login" settings write, so `force` takes them
  # back on rebuild. Gaming Mode's session runs no XDG autostart; OnlyShowIn
  # keeps it that way.
  autostart = {
    name,
    desktopName,
    icon,
    exec,
  }: {
    "autostart/${name}.desktop" = {
      source = "${pkgs.makeDesktopItem {
        inherit name desktopName icon exec;
        terminal = false;
        onlyShowIn = ["KDE"];
      }}/share/applications/${name}.desktop";
      force = true;
    };
  };

  # KWin has no declarative output scale or mode, so they are reasserted at
  # session start with kscreen-doctor, as Whopper does. DP-1 is the TV
  # through the DP->HDMI adapter. Plasma stays SDR; Gaming Mode does HDR.
  # Retries because the output may not be ready when the session starts;
  # every call is bounded because kscreen-doctor can hang.
  tvOutput = pkgs.writeShellScript "tv-output" ''
    doctor="${pkgs.coreutils}/bin/timeout 5 ${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor"
    for _ in $(seq 1 30); do
      if $doctor -o 2>/dev/null | grep -q 'DP-1'; then
        $doctor output.DP-1.enable output.DP-1.mode.3840x2160@120 output.DP-1.scale.2 && exit 0
      fi
      sleep 1
    done
    exit 0
  '';
in {
  xdg.configFile = lib.mergeAttrsList [
    # -silent: no main window.
    (autostart {
      name = "steam";
      desktopName = "Steam";
      icon = "steam";
      exec = "${desktopSteamExe} -silent";
    })
    # The package from the system module, which carries the polkit policy
    # owners (../modules/desktop.nix); --silent keeps the window closed.
    (autostart {
      name = "com.onepassword.OnePassword";
      desktopName = "1Password";
      icon = "1password";
      exec = "${lib.getExe osConfig.programs._1password-gui.package} --silent";
    })
  ];
  xdg.dataFile."applications/steam.desktop".source = desktopSteamEntry;

  systemd.user.services.tv-output = {
    Unit = {
      Description = "Set the TV to 3840x2160@120 at 200% scale under Plasma";
      After = ["plasma-workspace.target"];
      PartOf = ["graphical-session.target"];
      # Session-start job only; re-running it during Home Manager activation
      # can block the switch while kscreen-doctor hangs.
      X-RestartIfChanged = false;
    };
    Service = {
      Type = "oneshot";
      TimeoutStartSec = 200;
      RemainAfterExit = true;
      ExecStart = "${tvOutput}";
    };
    # Plasma only: Gaming Mode reaches graphical-session.target too, and
    # there kscreen-doctor has nothing to talk to.
    Install.WantedBy = ["plasma-workspace.target"];
  };

  programs.plasma = {
    enable = true;

    # Installed system-wide in ../modules/desktop.nix.
    workspace.lookAndFeel = "com.valve.vapor.desktop";

    # Konsole is gone (../modules/desktop.nix), so Dolphin's "Open Terminal
    # Here" goes to Ghostty, as on Whopper (hosts/whopper/home/desktop/
    # plasma.nix explains the flag). TerminalService would win over
    # TerminalApplication, so null deletes it.
    configFile.kdeglobals.General = {
      TerminalApplication = "ghostty --gtk-single-instance=false";
      TerminalService = null;
    };

    # Nobody locks a TV; Gaming Mode decides when the box sleeps.
    kscreenlocker = {
      autoLock = false;
      lockOnResume = false;
    };
    powerdevil.AC = {
      autoSuspend.action = "nothing";
      dimDisplay.enable = false;
      turnOffDisplay.idleTimeout = "never";
    };

    panels = [
      {
        location = "bottom";
        height = 64;
        widgets = [
          "org.kde.plasma.kickoff"
          {
            iconTasks.launchers = [
              "applications:return-to-gaming-mode.desktop"
              "applications:firefox.desktop"
              "applications:org.telegram.desktop.desktop"
              "applications:1password.desktop"
              "applications:org.kde.dolphin.desktop"
            ];
          }
          "org.kde.plasma.marginsseparator"
          "org.kde.plasma.systemtray"
          {
            digitalClock.time.format = "24h";
          }
        ];
      }
    ];
  };
}
