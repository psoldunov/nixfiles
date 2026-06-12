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
    ./xdg/portal.nix

    # Dev
    ./dev/neovim.nix
    ./dev/dev.nix

    # Desktop
    ./desktop/hyprland.nix
    ./desktop/hypridle.nix
    ./desktop/ags.nix
    ./desktop/rofi.nix
    ./desktop/pywal.nix
    ./desktop/mako.nix
    ./desktop/qt
    ./desktop/gtk

    # Programs
    ./programs/spotifyd.nix
    ./programs/kitty.nix
    ./programs/vscode.nix
  ];

  programs.home-manager.enable = true;

  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "peach";
    cursors = {
      enable = true;
      accent = "dark";
      flavor = "mocha";
    };
    hyprland.enable = false;
  };

  home.stateVersion = "23.11";
}
