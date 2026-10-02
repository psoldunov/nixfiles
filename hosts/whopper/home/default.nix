# Whopper-local home-manager aggregator. Pulls the shared modules at
# ../../../modules/home plus all desktop-only modules.
{...}: {
  imports = [
    # Shared modules
    ../../../modules/home

    # Whopper-local modules
    ./sops.nix
    ./ssh.nix
    ./dconf.nix
    ./services.nix
    ./packages.nix
    ./scripts
    ./browser/chromium.nix
    ./xdg/desktop-entries.nix
    ./xdg/mimeapps.nix
    ./xdg/autostart.nix

    # Dev
    ./dev/neovim.nix
    ./dev/dev.nix
    ./dev/playwright.nix
    ./dev/swift.nix

    # Desktop
    ./desktop/qt
    ./desktop/gtk
    ./desktop/plasma.nix
    ./desktop/plasma-shortcuts.nix
    ./desktop/remember-window-positions.nix

    # Programs
    ./programs/deckmaster
    ./programs/figma-linux-next.nix
    ./programs/spotifyd.nix
    ./programs/kitty.nix
    ./programs/skrepka.nix
    ./programs/solaar.nix
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
