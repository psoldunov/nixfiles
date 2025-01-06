{
  config,
  pkgs,
  pkgs-unstable,
  ...
}: {
  programs.vscode = {
    enable = true;
    package = pkgs-unstable.vscode;
    enableUpdateCheck = false;
    # extensions = with pkgs; [
    #   vscode-extensions.continue.continue
    #   vscode-extensions.formulahendry.auto-close-tag
    #   vscode-extensions.formulahendry.auto-rename-tag
    #   vscode-extensions.leonardssh.vscord
    # ];
  };
}
