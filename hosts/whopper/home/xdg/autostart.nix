{
  lib,
  pkgs,
  osConfig,
  ...
}: let
  # One XDG autostart entry per tray app, each launched straight into the tray.
  #
  # The file names match the ones the apps write themselves, so a "Launch at
  # login" toggle left on inside an app cannot add a second entry beside this
  # one. Slack's own toggle links /usr/share/applications/slack.desktop, which
  # does not exist on NixOS, and Telegram's writes its entry through the
  # background portal; `force` takes both paths back on rebuild instead of
  # piling up .hm-backup files. Turn those in-app toggles off: switching one off
  # later deletes the file, and with it this entry, until the next rebuild.
  # The same goes for entries added in Plasma's Autostart settings, which copy
  # the app's own .desktop file under its name.
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
    # Solaar's entry lives in ../programs/solaar.nix, which launches it
    # through a wrapper.
    #
    # The package comes from the system module: programs._1password-gui
    # overrides its package with the polkit policy owners, so pkgs._1password-gui
    # would be a second copy of the app.
    (autostart {
      name = "com.onepassword.OnePassword";
      desktopName = "1Password";
      icon = "1password";
      exec = "${lib.getExe osConfig.programs._1password-gui.package} --silent";
    })
    # The cap_net_admin wrapper from programs.librepods, not the store binary.
    # The in-app toggle writes this same file name.
    (autostart {
      name = "librepods";
      desktopName = "LibrePods";
      icon = "librepods";
      exec = "${osConfig.security.wrapperDir}/librepods --hide";
    })
  ];
}
