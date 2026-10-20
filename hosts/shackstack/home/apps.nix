# Apps for Desktop Mode: launchers for the non-Steam stores, the
# emulators, and a terminal and an editor for fixing things on the TV.
# DuckStation and P.T. come from the overlays in ../modules/desktop.nix;
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
    # P.T. from the PS4 PKG, as on Whopper; the game files and saves live in
    # ~/.local/share/pt-pc (overlays/pt-pc).
    pt-pc
  ];

  programs.vscode.enable = true;
}
