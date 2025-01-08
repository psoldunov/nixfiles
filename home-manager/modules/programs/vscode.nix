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
      "projectManager.tags" = ["Personal" "Boundary" "System"];
      "projectManager.sortList" = "Saved";
      "workbench.iconTheme" = "catppuccin-mocha";
      "workbench.colorTheme" = "Catppuccin Mocha";
      "catppuccin.accentColor" = "blue";
      "window.titleBarStyle" = "custom";
      "editor.formatOnType" = true;
      "window.zoomLevel" = 1;
      "C_Cpp.default.compilerPath" = "/run/current-system/sw/bin/gcc";
      "editor.tabSize" = 2;
      "remote.SSH.remotePlatform" = {
        "10.24.24.9" = "linux";
        "10.24.24.2" = "linux";
        "10.24.24.6" = "macOS";
        "10.24.24.5" = "linux";
        "10.24.24.7" = "linux";
      };
      "[javascript]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "[json]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "[jsonc]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "[typescript]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "[typescriptreact]" = {
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
      };
      "editor.fontFamily" = "JetBrainsMono Nerd Font";
      "editor.fontSize" = 16;
      "editor.semanticHighlighting.enabled" = true;
      "terminal.integrated.minimumContrastRatio" = 1;
      "gopls" = {
        "ui.semanticTokens" = true;
      };
      "files.associations" = {
        ".env*" = "dotenv";
        "*.css" = "tailwindcss";
      };
    };
    extensions = with pkgs.vscode-extensions;
      [
        alefragnani.project-manager
        bbenoist.nix
        bradlc.vscode-tailwindcss
        (catppuccin.catppuccin-vsc.override {
          accent = "blue";
        })
        catppuccin.catppuccin-vsc-icons
        continue.continue
        denoland.vscode-deno
        eamodio.gitlens
        esbenp.prettier-vscode
        formulahendry.auto-close-tag
        formulahendry.auto-rename-tag
        github.vscode-github-actions
        gruntfuggly.todo-tree
        golang.go
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
        dbaeumer.vscode-eslint
        # vscodevim.vim
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
        {
          name = "remote-explorer";
          publisher = "ms-vscode";
          version = "0.4.3";
          sha256 = "772l0EnAWXLg53TxPZf93js/W49uozwdslmzNwD1vIk=";
        }
      ];
  };
}
