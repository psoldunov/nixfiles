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
# Only the enable flag is declared. The script settings (mode, blacklist,
# whitelist) stay editable in System Settings > Window Management > KWin
# Scripts and are written to [Script-rememberwindowpositions] in kwinrc. The
# saved window data lives in ~/.config/kde.org/kwin.conf, which plasma-manager
# does not touch, so a rebuild keeps it.
{pkgs, ...}: let
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

  programs.plasma.configFile.kwinrc.Plugins.rememberwindowpositionsEnabled = true;
}
