{
  lib,
  pkgs,
  ...
}: let
  # One XDG autostart entry per chat app, each launched straight into the tray.
  #
  # The file names match the ones the apps write themselves, so a "Launch at
  # login" toggle left on inside an app cannot add a second entry beside this
  # one. Slack's own toggle links /usr/share/applications/slack.desktop, which
  # does not exist on NixOS, and Telegram's writes its entry through the
  # background portal; `force` takes both paths back on rebuild instead of
  # piling up .hm-backup files. Turn those in-app toggles off: switching one off
  # later deletes the file, and with it this entry, until the next rebuild.
  autostart = {
    name,
    desktopName,
    icon,
    exec,
  }: {
    "autostart/${name}.desktop" = {
      source = "${pkgs.makeDesktopItem {
        inherit name desktopName icon exec;
        terminal = false;
      }}/share/applications/${name}.desktop";
      force = true;
    };
  };
in {
  xdg.configFile = lib.mergeAttrsList [
    # -u marks a login launch; Slack then stays hidden while its "Hide on
    # startup" setting is on, which is its default.
    (autostart {
      name = "slack";
      desktopName = "Slack";
      icon = "slack";
      exec = "${pkgs.slack}/bin/slack -u";
    })
    (autostart {
      name = "legcord";
      desktopName = "Legcord";
      icon = "legcord";
      exec = "${pkgs.legcord}/bin/legcord --start-in-tray";
    })
    (autostart {
      name = "org.telegram.desktop";
      desktopName = "Telegram";
      icon = "org.telegram.desktop";
      exec = "${pkgs.telegram-desktop}/bin/Telegram -startintray";
    })
  ];
}
