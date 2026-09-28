# DuckStation — the PlayStation 1 emulator by stenzek. nixpkgs dropped its
# source build at upstream's request (the `duckstation` attr is now a throwing
# alias) and upstream only ships prebuilt AppImages for Linux, so we wrap the
# release AppImage in an FHS env with appimageTools and lift the desktop entry,
# icons and metainfo out of it so Plasma lists it like a native app.
#
# Pinned to a versioned `v0.1-NNNNN` tag rather than the rolling `latest`
# release: upstream re-uploads `latest` in place, which breaks the fixed-output
# hash on the next rebuild. To bump, take the newest tag from
#   gh release list -R stenzek/duckstation
# and refresh the hash with
#   nix store prefetch-file https://github.com/stenzek/duckstation/releases/download/v<version>/DuckStation-x64.AppImage
self: super: let
  pname = "duckstation";
  version = "0.1-11826";

  src = super.fetchurl {
    url = "https://github.com/stenzek/duckstation/releases/download/v${version}/DuckStation-x64.AppImage";
    hash = "sha256-xcip3k38EOeUE33Li6uXYMpXjfKqe+jBIVFxvru6WWU=";
  };

  appimageContents = super.appimageTools.extract {inherit pname version src;};
in {
  duckstation = super.appimageTools.wrapType2 {
    inherit pname version src;

    # The AppImage bundles its own Qt. The Plasma session exports
    # QT_PLUGIN_PATH / QML2_IMPORT_PATH pointing at nixpkgs' Qt, whose plugins
    # the bundled Qt then loads and aborts on (Qt_6_PRIVATE_API mismatch).
    # QT_QPA_PLATFORMTHEME=kde names a plugin the bundle lacks; left unset,
    # DuckStation picks its bundled xdgdesktopportal theme (portal dialogs).
    profile = ''
      unset QT_PLUGIN_PATH QML2_IMPORT_PATH QT_QPA_PLATFORMTHEME
    '';

    # The AppImage's entry runs `duckstation-qt`; the wrapper is `duckstation`.
    extraInstallCommands = ''
      install -Dm444 \
        ${appimageContents}/usr/share/applications/org.duckstation.DuckStation.desktop \
        -t $out/share/applications
      substituteInPlace $out/share/applications/org.duckstation.DuckStation.desktop \
        --replace-fail duckstation-qt duckstation
      install -Dm444 \
        ${appimageContents}/usr/share/metainfo/org.duckstation.DuckStation.metainfo.xml \
        -t $out/share/metainfo
      cp -r --no-preserve=mode ${appimageContents}/usr/share/icons $out/share/icons
    '';

    meta = {
      description = "Fast PlayStation 1 emulator (upstream AppImage)";
      homepage = "https://www.duckstation.org";
      license = super.lib.licenses.cc-by-nc-nd-40;
      sourceProvenance = [super.lib.sourceTypes.binaryNativeCode];
      mainProgram = "duckstation";
      platforms = ["x86_64-linux"];
    };
  };
}
