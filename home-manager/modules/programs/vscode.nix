{
  config,
  pkgs,
  pkgs-stable,
  ...
}: {
  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    extensions = with pkgs;
      [
        vscode-extensions.continue.continue
        vscode-extensions.formulahendry.auto-close-tag
        vscode-extensions.formulahendry.auto-rename-tag
        vscode-extensions.leonardssh.vscord
      ]
      ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "figma-vscode-extension";
          publisher = "figma";
          version = "0.4.0";
          sha256 = "3D9z/eHoIAhySLabnhtQCNqSDh7b30XXaBrGeL0zZwA=";
        }
      ];
  };
}
