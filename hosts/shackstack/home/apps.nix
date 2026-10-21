# Apps for Desktop Mode: launchers for the non-Steam stores, the
# emulators, and a terminal and an editor for fixing things on the TV.
# DuckStation comes from the overlay in ../modules/desktop.nix;
# Zen from modules/home/programs/zen.nix (flake.nix) and Ghostty from
# modules/home/workstation/ghostty.nix (./default.nix). Protontricks is
# programs.steam.protontricks in ../modules/game-mode.nix.
{pkgs, ...}: {
  home.packages = with pkgs; [
    heroic
    lutris
    duckstation
    pcsx2
    ryubing
    protonup-qt
    steam-rom-manager
    # Jellyfin client, as on Whopper. Gaming Mode gets it as a non-Steam
    # shortcut (programs.steam.config in ../modules/game-mode.nix).
    fladder
  ];

  programs.vscode.enable = true;
}
