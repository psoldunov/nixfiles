{config, ...}: {
  imports = [
    ./shell/shell.nix
    ./dev/neovim.nix
    ./dev/dev.nix
    ./desktop/hyprland.nix
    ./desktop/hypridle.nix
    ./desktop/ags.nix
    ./desktop/rofi.nix
    ./desktop/pywal.nix
    ./desktop/mako.nix
    ./desktop/qt
    ./desktop/gtk
    ./git/git.nix
    ./programs/ncmpcpp.nix
    ./programs/spotifyd.nix
    ./programs/kitty.nix
    ./programs/zed.nix
  ];
}
