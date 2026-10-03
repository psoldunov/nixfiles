# KWin remembers where every app window was, with no per-app rules.
#
# Under Wayland an app cannot place its own window, and KWin has no global
# "remember window positions" switch (that option is X11 only). Plasma 6.4+
# speaks the xdg-session-management protocol, but each toolkit and app has to
# opt in, so most windows still open wherever KWin's placement policy puts them.
#
# The Remember Window Positions KWin script (rxappdev, GPL-3.0) fills the gap.
# When the last window of an app closes, the script saves the position, size,
# screen, virtual desktop and Keep Above state of its windows. It restores them
# the next time the app starts. Multi-window apps such as browsers are matched
# window by window by caption.
#
# The enable flag and the blacklist are declared. The other script settings
# (mode, whitelist) stay editable in System Settings > Window Management > KWin
# Scripts and are written to [Script-rememberwindowpositions] in kwinrc. A
# blacklist edited there is reset on the next rebuild. The saved window data
# lives in ~/.config/kde.org/kwin.conf, which plasma-manager does not touch, so
# a rebuild keeps it.
{pkgs, ...}: let
  # Window classes (resourceClass) the script never saves or restores. A `*`
  # matches any run of characters. Setting the key replaces the upstream
  # default list, so its entries are repeated before ours.
  blacklist = [
    # Upstream defaults, from contents/config/main.xml of v7.0.0.
    "org.kde.spectacle"
    "org.kde.polkit-kde-authentication-agent-1"
    "steam*"
    "org.kde.plasmashell"
    "kwin"
    "ksmserver"
    "systemsettings"
    "kcm_kwinrules"
    "org.kde.kmenuedit"
    "org.kde.ark"
    "org.kde.plasma.emojier"
    "org.freedesktop.impl.portal.desktop.kde"

    # Figma windows open where KWin's placement policy puts them.
    "figma"
  ];

  rememberWindowPositions = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "kwin-remember-window-positions";
    version = "7.0.0";

    src = pkgs.fetchFromGitHub {
      owner = "rxappdev";
      repo = "RememberWindowPositions";
      rev = "v${version}";
      hash = "sha256-mlTF1DJpYKbUgFoFPXhLng6s6z8YbYam2VfdxhbUjtk=";
    };

    dontBuild = true;

    # KWin finds scripts under kwin/scripts/<plugin id> in XDG_DATA_DIRS.
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/kwin/scripts
      cp -r src $out/share/kwin/scripts/rememberwindowpositions
      runHook postInstall
    '';

    meta = {
      description = "KWin script that saves and restores application window positions";
      homepage = "https://github.com/rxappdev/RememberWindowPositions";
      license = pkgs.lib.licenses.gpl3Only;
      platforms = pkgs.lib.platforms.linux;
    };
  };
in {
  home.packages = [rememberWindowPositions];

  programs.plasma.configFile.kwinrc = {
    Plugins.rememberwindowpositionsEnabled = true;
    Script-rememberwindowpositions.blacklist = builtins.concatStringsSep "\n" blacklist;
  };
}
