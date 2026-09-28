{pkgs, ...}: let
  # Locally-used browser launcher references. Kept here because the desktop
  # entries below invoke browsers with --app= flags and we do not want to
  # pull in programs.chromium as a dependency of this file.
  brave = "${pkgs.brave}/bin/brave";
in {
  xdg.desktopEntries = {
    lm-studio = {
      name = "LM Studio";
      icon = "${pkgs.lmstudio}/share/icons/hicolor/0x0/apps/lm-studio.png";
      exec = "${pkgs.lmstudio}/bin/lm-studio -ozone-platform=wayland";
      terminal = false;
      mimeType = ["x-scheme-handler/lmstudio"];
      categories = ["Development" "Utility"];
      comment = "Use the chat UI or local server to experiment and develop with local LLMs.";
    };
    webflow = {
      name = "Webflow";
      genericName = "Web Editor";
      icon = ../desktop/assets/webflow.png;
      exec = ''${brave} --new-window --app="https://webflow.com/dashboard?r=1&workspace=boundary-digital-llc" %U'';
      terminal = false;
      mimeType = ["x-scheme-handler/webflow"];
      categories = ["Development"];
    };
    memos = {
      name = "Memos";
      genericName = "Notes Manager";
      icon = pkgs.fetchurl {
        url = "https://avatars.githubusercontent.com/u/95764151?s=64";
        sha256 = "1x97jwi994jlglmk9v8hf4cdmh2kdnbjjil9bipvh204c4ypjhqw";
      };
      exec = ''${brave}  --new-window --app="https://memos.theswisscheese.com" %U'';
      terminal = false;
      mimeType = ["x-scheme-handler/memos"];
      categories = ["Office"];
    };
    motrix = {
      name = "Motrix";
      genericName = "Download Manager";
      exec = "${pkgs.motrix}/bin/motrix --ozone-platform-hint=auto --no-sandbox %U";
      terminal = false;
      icon = "motrix";
      comment = "A full-featured download manager";
      mimeType = [
        "application/x-bittorrent"
        "x-scheme-handler/magnet"
        "application/x-bittorrent"
        "x-scheme-handler/mo"
        "x-scheme-handler/motrix"
        "x-scheme-handler/magnet"
        "x-scheme-handler/thunder"
      ];
      categories = ["Network"];
    };
    "nixfiles-code" = {
      name = "Open Nixfiles in VS Code";
      genericName = "This opens nixfiles in VS Code";
      icon = "nix-snowflake";
      exec = "${pkgs.vscode}/bin/code -n /home/psoldunov/.nixfiles";
    };
    "open-clockify" = {
      name = "Open Clockify in Browser";
      genericName = "Time Tracker";
      icon = pkgs.fetchurl {
        url = "https://brand.cake.com/wp-content/uploads/2024/02/logo-light-bg-2.png";
        sha256 = "0fv5j5gcsjxp8bq58y04wqwji8cvksk8sisipm44kyj70hpyjb0m";
      };
      exec = "${brave} --new-window https://app.clockify.me/timesheet";
    };
    "clockify" = {
      name = "Clockify";
      genericName = "Time Tracker";
      icon = "${pkgs.clockify}/share/pixmaps/clockify.png";
      exec = "${pkgs.clockify}/bin/clockify -ozone-platform=wayland --no-sandbox %U";
      terminal = false;
      mimeType = ["x-scheme-handler/clockify"];
      categories = ["Development"];
    };
  };
}
