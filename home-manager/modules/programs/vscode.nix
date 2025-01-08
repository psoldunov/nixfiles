{
  config,
  pkgs,
  pkgs-stable,
  ...
}: {
  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    userSettings = {
      "workbench.iconTheme" = "vscode-icons";
      "workbench.colorTheme" = "Catppuccin Mocha";
      "catppuccin.accentColor" = "peach";
      "window.titleBarStyle" = "native";
    };
    extensions = with pkgs.vscode-extensions;
      [
        alefragnani.project-manager
        bbenoist.nix
        bradlc.vscode-tailwindcss
        catppuccin.catppuccin-vsc
        catppuccin.catppuccin-vsc-icons
        continue.continue
        denoland.vscode-deno
        eamodio.gitlens
        esbenp.prettier-vscode
        formulahendry.auto-close-tag
        formulahendry.auto-rename-tag
        github.vscode-github-actions
        gruntfuggly.todo-tree
        kamadorueda.alejandra
        leonardssh.vscord
        mikestead.dotenv
        ms-azuretools.vscode-docker
        ms-vscode.cmake-tools
        ms-vscode.cpptools
        ms-vscode.cpptools-extension-pack
        ms-vscode-remote.remote-ssh
        prisma.prisma
        tamasfe.even-better-toml
        vincaslt.highlight-matching-tag
        vscode-icons-team.vscode-icons
        vscodevim.vim
        wix.vscode-import-cost
        yoavbls.pretty-ts-errors
      ]
      ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "figma-vscode-extension";
          publisher = "figma";
          version = "0.4.0";
          sha256 = "3D9z/eHoIAhySLabnhtQCNqSDh7b30XXaBrGeL0zZwA=";
        }
        {
          name = "vscode-sanity";
          publisher = "sanity-io";
          version = "0.2.1";
          sha256 = "krIalO1/APMvCUXkSptnYWddUY1vjdXBkgfLVKwgiHA=";
        }
      ];
  };
}
