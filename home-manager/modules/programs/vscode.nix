{
  config,
  pkgs,
  pkgs-stable,
  ...
}: let
  enableContinue = false;
  enableVimMode = false;
in {
  programs.vscode = {
    enable = true;
    # profiles.default = {
    #   enableUpdateCheck = false;
    #   enableExtensionUpdateCheck = false;
    #   userSettings = {
    #     "projectManager.tags" = ["Personal" "Boundary" "System"];
    #     "projectManager.sortList" = "Saved";
    #     "workbench.iconTheme" = "catppuccin-mocha";
    #     "workbench.colorTheme" = "Catppuccin Mocha";
    #     "workbench.startupEditor" = "none";
    #     "catppuccin.accentColor" = "peach";
    #     "window.titleBarStyle" = "native";
    #     "editor.formatOnType" = true;
    #     "window.zoomLevel" = 1;
    #     "C_Cpp.default.compilerPath" = "/run/current-system/sw/bin/gcc";
    #     "editor.tabSize" = 2;
    #     "remote.SSH.remotePlatform" = {
    #       "10.24.24.9" = "linux";
    #       "10.24.24.2" = "linux";
    #       "10.24.24.6" = "macOS";
    #       "10.24.24.5" = "linux";
    #       "10.24.24.7" = "linux";
    #     };
    #     "editor.defaultFormatter" = "esbenp.prettier-vscode";
    #     "[javascript]" = {
    #       "editor.defaultFormatter" = "esbenp.prettier-vscode";
    #     };
    #     "[json]" = {
    #       "editor.defaultFormatter" = "esbenp.prettier-vscode";
    #     };
    #     "[jsonc]" = {
    #       "editor.defaultFormatter" = "esbenp.prettier-vscode";
    #     };
    #     "[typescript]" = {
    #       "editor.defaultFormatter" = "esbenp.prettier-vscode";
    #     };
    #     "[typescriptreact]" = {
    #       "editor.defaultFormatter" = "esbenp.prettier-vscode";
    #     };
    #     "editor.fontFamily" = "JetBrainsMono Nerd Font";
    #     "editor.fontSize" = 16;
    #     "editor.semanticHighlighting.enabled" = true;
    #     "terminal.integrated.minimumContrastRatio" = 1;
    #     "gopls" = {
    #       "ui.semanticTokens" = true;
    #     };
    #     "files.associations" = {
    #       ".env*" = "dotenv";
    #       "*.css" = "tailwindcss";
    #     };
    #     "window.menuBarVisibility" = "toggle";
    #     "window.customTitleBarVisibility" = "auto";
    #     "emmet.syntaxProfiles" = {
    #       "html" = {
    #         "attr_quotes" = "single";
    #       };
    #       "js" = {
    #         "attr_quotes" = "single";
    #         "self_closing_tag" = true;
    #       };
    #       "jsx" = {
    #         "attr_quotes" = "single";
    #         "self_closing_tag" = true;
    #       };
    #       "xml" = {
    #         "attr_quotes" = "single";
    #       };
    #     };
    #     "editor.quickSuggestions" = {
    #       "strings" = "on";
    #     };
    #     "javascript.format.enable" = true;
    #     "javascript.format.semicolons" = "insert";
    #     "typescript.format.enable" = true;
    #     "typescript.format.semicolons" = "insert";
    #     "diffEditor.codeLens" = true;
    #     "remote.SSH.useLocalServer" = false;
    #     "editor.formatOnPaste" = true;
    #     "editor.formatOnSave" = true;
    #     "chat.commandCenter.enabled" =
    #       !enableContinue;
    #     "explorer.confirmDragAndDrop" = false;
    #     "explorer.confirmDelete" = false;
    #     "editor.wordWrap" = "on";
    #     "extensions.autoUpdate" = false;
    #   };
    #   extensions = with pkgs.vscode-extensions;
    #     [
    #       alefragnani.project-manager
    #       bbenoist.nix
    #       bradlc.vscode-tailwindcss
    #       (catppuccin.catppuccin-vsc.override {
    #         accent = "blue";
    #       })
    #       catppuccin.catppuccin-vsc-icons
    #       denoland.vscode-deno
    #       eamodio.gitlens
    #       esbenp.prettier-vscode
    #       formulahendry.auto-close-tag
    #       formulahendry.auto-rename-tag
    #       github.vscode-github-actions
    #       gruntfuggly.todo-tree
    #       golang.go
    #       kamadorueda.alejandra
    #       leonardssh.vscord
    #       mikestead.dotenv
    #       ms-azuretools.vscode-docker
    #       ms-vscode.cmake-tools
    #       ms-vscode.cpptools
    #       ms-vscode.cpptools-extension-pack
    #       ms-vscode-remote.remote-ssh
    #       christian-kohler.npm-intellisense
    #       prisma.prisma
    #       tamasfe.even-better-toml
    #       vincaslt.highlight-matching-tag
    #       dbaeumer.vscode-eslint
    #       graphql.vscode-graphql
    #       graphql.vscode-graphql-syntax
    #       wix.vscode-import-cost
    #       yoavbls.pretty-ts-errors
    #     ]
    #     ++ (
    #       if enableVimMode
    #       then
    #         with pkgs.vscode-extensions; [
    #           vscodevim.vim
    #         ]
    #       else []
    #     )
    #     ++ (
    #       if enableContinue
    #       then
    #         with pkgs.vscode-extensions; [
    #           continue.continue
    #         ]
    #       else
    #         with pkgs.vscode-extensions; [
    #           github.copilot
    #           github.copilot-chat
    #         ]
    #     )
    #     ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
    #       {
    #         name = "figma-vscode-extension";
    #         publisher = "figma";
    #         version = "0.4.0";
    #         sha256 = "3D9z/eHoIAhySLabnhtQCNqSDh7b30XXaBrGeL0zZwA=";
    #       }
    #       {
    #         name = "vscode-sanity";
    #         publisher = "sanity-io";
    #         version = "0.2.1";
    #         sha256 = "krIalO1/APMvCUXkSptnYWddUY1vjdXBkgfLVKwgiHA=";
    #       }
    #       {
    #         name = "remote-explorer";
    #         publisher = "ms-vscode";
    #         version = "0.5.2025021709";
    #         sha256 = "tCNkC7qa59oL9TXA+OKN0Tq5wl0TOLJhHpiKRLmMlgo=";
    #       }
    #     ];
    # };
  };
}
