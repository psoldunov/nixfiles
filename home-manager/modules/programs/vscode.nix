{
  config,
  pkgs,
  ...
}: {
  programs.vscode = {
    enable = false;
    enableUpdateCheck = false;
    # extensions = with pkgs; [
    #   vscode-extensions.continue.continue
    #   vscode-extensions.formulahendry.auto-close-tag
    #   vscode-extensions.formulahendry.auto-rename-tag
    #   vscode-extensions.catppuccin.catppuccin-vsc-icons
    #   vscode-extensions.catppuccin.catppuccin-vsc
    #   vscode-extensions.leonardssh.vscord
    # ];
  };
}
