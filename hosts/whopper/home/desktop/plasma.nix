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
{...}: {
  programs.plasma = {
    enable = true;

    workspace.lookAndFeel = "com.valve.vapor.desktop";

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
