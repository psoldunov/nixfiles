{
  config,
  pkgs,
  ...
}: {
  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    # extensions = with pkgs; [
    #   vscode-extensions.continue.continue
    #   vscode-extensions.formulahendry.auto-close-tag
    #   vscode-extensions.formulahendry.auto-rename-tag
    #   vscode-extensions.leonardssh.vscord
    # ];
  };
}
