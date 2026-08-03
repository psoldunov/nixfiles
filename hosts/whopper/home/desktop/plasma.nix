# Declarative KDE Plasma 6 config via plasma-manager.
#
# - Global theme: Vapor (SteamOS BreezeDark variant), packaged in
#   overlays/vapor-kde.nix and installed system-wide in modules/packages.nix.
# - Panel: a single bottom panel whose Kickoff launcher uses the NixOS
#   snowflake as its start-button icon (nix-snowflake, from nixos-icons).
#
# NOTE: because `panels` is defined here, plasma-manager owns the panel layout —
# manual panel edits in System Settings are reset on the next rebuild. The Vapor
# global theme still drives colors, Plasma style, and window decorations.
{pkgs, ...}: let
  # KWin (Wayland) picks its own mode each session and there is no declarative
  # KScreen mode option, so we reassert the desired mode at graphical-session
  # start via kscreen-doctor. DP-1 is the primary display; 3840x2160@120 is a
  # native EDID mode. Retries because the output may not be ready the instant
  # the session target activates.
  forceRefreshRate = pkgs.writeShellScript "force-refresh-rate" ''
    doctor=${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor
    for _ in $(seq 1 30); do
      if $doctor -o 2>/dev/null | grep -q 'DP-1'; then
        $doctor output.DP-1.enable output.DP-1.mode.3840x2160@120 && exit 0
      fi
      sleep 1
    done
    exit 0
  '';
in {
  systemd.user.services.force-refresh-rate = {
    Unit = {
      Description = "Force DP-1 to 3840x2160@120 under Plasma Wayland";
      After = ["plasma-workspace.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${forceRefreshRate}";
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  programs.plasma = {
    enable = true;

    workspace.lookAndFeel = "com.valve.vapor.desktop";

    # SF Pro Display everywhere in the Plasma UI. The family comes from
    # appleFonts.sf-pro, installed system-wide in modules/fonts.nix.
    # Written to kdeglobals ([General] font/smallestReadableFont/toolBarFont/
    # menuFont and [WM] activeFont), so Qt/KDE apps pick it up too.
    fonts = let
      ui = size: {
        family = "SF Pro Display";
        pointSize = size;
      };
    in {
      general = ui 10;
      menu = ui 10;
      toolbar = ui 10;
      windowTitle = ui 10;
      small = ui 8;
    };

    panels = [
      {
        location = "bottom";
        height = 44;
        widgets = [
          {
            kickoff = {
              icon = "nix-snowflake";
              sortAlphabetically = true;
            };
          }
          {
            iconTasks = {
              launchers = [
                "applications:zen.desktop"
                "applications:org.kde.dolphin.desktop"
                "applications:code.desktop"
                "applications:kitty.desktop"
              ];
            };
          }
          "org.kde.plasma.marginsseparator"
          "org.kde.plasma.systemtray"
          {
            digitalClock = {
              time.format = "24h";
            };
          }
        ];
      }
    ];
  };
}
