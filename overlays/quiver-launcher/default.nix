# Quiver Launcher — installs and runs apps and games (N64 recomps and the
# like) from GitHub/GitLab release assets. Not in nixpkgs, and upstream ships
# a self-contained .NET 10 / Avalonia AppImage for Linux, so we wrap the
# release AppImage in an FHS env with appimageTools and lift the desktop entry
# and icon out of it so Plasma lists it like a native app.
#
# Library data (apps.json, settings.json, Apps/, Cache/) normally lives beside
# the AppImage. appimageTools runs the extracted tree without setting
# $APPIMAGE, so Quiver falls back to ~/.local/share/QuiverLauncher.
#
# Pinned (version + hash in pin.json next to this file) to the latest stable
# release. `update_system` refreshes the pin before every rebuild. To refresh
# it on its own, run `update_quiver_launcher` (optionally with a version such
# as `3.4.5`) and rebuild.
self: super: let
  pname = "quiver-launcher";
  pin = super.lib.importJSON ./pin.json;
  inherit (pin) version;

  src = super.fetchurl {
    url = "https://github.com/tgeorgiadis/quiver-launcher/releases/download/v${version}/QuiverLauncher-linux-x64.AppImage";
    inherit (pin) hash;
  };

  appimageContents = super.appimageTools.extract {inherit pname version src;};
in {
  quiver-launcher = super.appimageTools.wrapType2 {
    inherit pname version src;

    # The bundled .NET runtime dlopens ICU for globalization and aborts at
    # startup without it; appimageTools' default FHS env does not carry it.
    extraPkgs = pkgs: [pkgs.icu];

    # Self-update (Velopack) would rewrite a store path; the pin updates it.
    # Apps Quiver downloads as AppImages run inside this bubblewrap sandbox,
    # where the setuid fusermount can't mount them; extract-and-run sidesteps
    # FUSE.
    profile = ''
      export QuiverLauncher_SKIP_UPDATES=1
      export APPIMAGE_EXTRACT_AND_RUN=1
    '';

    # The AppImage's entry runs `QuiverLauncher`; the wrapper is
    # `quiver-launcher`. Upstream files its 256px PNG icon under
    # hicolor/scalable, which icon themes only search for SVGs.
    extraInstallCommands = ''
      install -Dm444 ${appimageContents}/QuiverLauncher.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/QuiverLauncher.desktop \
        --replace-fail 'Exec=QuiverLauncher' 'Exec=quiver-launcher' \
        --replace-fail 'Name=QuiverLauncher' 'Name=Quiver Launcher' \
        --replace-fail 'Categories=Utility;' 'Categories=Game;Utility;'
      install -Dm444 ${appimageContents}/QuiverLauncher.png \
        $out/share/icons/hicolor/256x256/apps/QuiverLauncher.png
    '';

    meta = {
      description = "Launcher for apps and games from GitHub/GitLab releases (upstream AppImage)";
      homepage = "https://github.com/tgeorgiadis/quiver-launcher";
      license = super.lib.licenses.mit;
      sourceProvenance = [super.lib.sourceTypes.binaryNativeCode];
      mainProgram = "quiver-launcher";
      platforms = ["x86_64-linux"];
    };
  };
}
