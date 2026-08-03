# Generates one XDG desktop entry per project from ./dev/projects.nix, each
# opening the project in VSCode. The entries surface in KRunner (Alt+Space) and
# the Kickoff app menu — a stock-KDE replacement for the old rofi project
# launcher. Search "project" or a project name in KRunner to jump to one.
{
  config,
  pkgs,
  ...
}: let
  projects = import ../dev/projects.nix {inherit config;};
in {
  xdg.desktopEntries =
    builtins.listToAttrs (map (p: {
        name = "project-${p.name}";
        value = {
          name = p.name;
          genericName = "Project";
          comment = "Open ${p.name} in VSCode";
          exec = "${pkgs.vscode}/bin/code ${p.path}";
          icon = "vscode";
          terminal = false;
          type = "Application";
          categories = ["Development"];
          settings.Keywords = "project;code;vscode;${p.name};";
        };
      })
      projects.items);
}
