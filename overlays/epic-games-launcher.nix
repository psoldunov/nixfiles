# Epic Games Launcher — Epic's native Linux launcher (a Tauri app), wrapped
# from the official AppImage. The AppImage bundles its own WebKitGTK, GTK3
# and GStreamer, so appimageTools' FHS env needs nothing extra.
#
# The launcher's built-in self-updater rewrites the AppImage in place, which
# can't work from the read-only store, so updates come from bumping this pin.
#
# shortcut: Epic serves the AppImage from an unversioned URL, so the hash
# breaks as soon as Epic ships a new build. A machine that already has this
# store path keeps building; a fresh one fails the fetch. To bump, run
#   nix store prefetch-file https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncher-x86_64.AppImage
# take the new hash, and set `version` from the binary's user agent:
#   strings usr/bin/EpicGamesLauncher | grep -o 'EpicGamesLauncher/[0-9.]*'
self: super: let
  pname = "epic-games-launcher";
  version = "0.102.0";

  src = super.fetchurl {
    url = "https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncher-x86_64.AppImage";
    name = "EpicGamesLauncher-${version}-x86_64.AppImage";
    hash = "sha256-lGmTvIycnRbocDXJZL1wYnLDW18EhkmOxbcHvg2xpXg=";
  };

  appimageContents = super.appimageTools.extract {inherit pname version src;};
in {
  epic-games-launcher = super.appimageTools.wrapType2 {
    inherit pname version src;

    # The desktop entry runs `EpicGamesLauncher`; the wrapper is
    # `epic-games-launcher`.
    extraInstallCommands = ''
      install -Dm444 ${appimageContents}/usr/share/applications/epic-games-launcher.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/epic-games-launcher.desktop \
        --replace-fail 'Exec=EpicGamesLauncher' 'Exec=${pname}'
      cp -r --no-preserve=mode ${appimageContents}/usr/share/icons $out/share/icons
    '';

    meta = {
      description = "Epic Games Launcher (upstream AppImage)";
      homepage = "https://store.epicgames.com";
      license = super.lib.licenses.unfree;
      sourceProvenance = [super.lib.sourceTypes.binaryNativeCode];
      mainProgram = pname;
      platforms = ["x86_64-linux"];
    };
  };
}
