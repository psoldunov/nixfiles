# Whopper-local home-manager aggregator. Pulls the shared modules at
# ../../../modules/home, the workstation layer it shares with BigMac, and
# all desktop-only modules.
{...}: {
  imports = [
    # Shared modules
    ../../../modules/home
    ../../../modules/home/workstation

    # Whopper-local modules
    ./sops.nix
    ./dconf.nix
    ./services.nix
    ./packages.nix
    ./scripts
    ./browser/chrome.nix
    ./xdg/desktop-entries.nix
    ./xdg/mimeapps.nix
    ./xdg/autostart.nix

    # Dev
    ./dev/neovim.nix
    ./dev/dev.nix
    ./dev/swift.nix

    # Desktop
    ./desktop/qt
    ./desktop/gtk
    ./desktop/plasma.nix
    ./desktop/plasma-shortcuts.nix

    # Programs
    ./programs/clokkr.nix
    ./programs/concierge.nix
    ./programs/deckmaster
    ./programs/figma.nix
    ./programs/ghostty.nix
    ./programs/spotifyd.nix
    ./programs/linear.nix
    ./programs/notion.nix
    ./programs/notion-calendar.nix
    ./programs/numero.nix
    ./programs/skrepka.nix
    ./programs/solaar.nix
    ./programs/strata.nix
    ./programs/token-station.nix
    ./programs/vscode.nix
    ./programs/wye.nix
  ];

  programs.home-manager.enable = true;

  # Stock KDE look: no catppuccin theming. Plasma/Qt/GTK all use Breeze.
  # Explicit autoEnable silences the upcoming-default warning; the global
  # toggle stays off so no port applies.
  catppuccin = {
    enable = false;
    autoEnable = false;
  };

  home.stateVersion = "23.11";
}
