{pkgs, ...}: let
  # Locally-used browser launcher reference. Kept here because a desktop entry
  # below opens a URL in Chrome and we do not want to pull in
  # programs.google-chrome as a dependency of this file.
  chrome = "${pkgs.google-chrome}/bin/google-chrome-stable";
in {
  xdg.desktopEntries = {
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
      # "Profile 2" is the Almost Always profile (~/.config/google-chrome/Local State).
      exec = ''${chrome} --profile-directory="Profile 2" --new-window https://app.clockify.me/timesheet'';
    };
    # Hide the launcher entry the neovim package ships; nvim stays on PATH.
    nvim = {
      name = "Neovim wrapper";
      exec = "nvim %F";
      terminal = true;
      noDisplay = true;
    };
  };
}
