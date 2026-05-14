{...}: {
  imports = [
    # Split from home.nix
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

    # Shell
    ./shell/shell.nix

    # Dev
    ./dev/neovim.nix
    ./dev/dev.nix
    ./git/git.nix

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
    ./programs/claude-code
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
  };

  home.stateVersion = "23.11";
}
