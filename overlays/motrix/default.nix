# Motrix — tracks the newest upstream release, prereleases included, instead
# of whatever nixpkgs last merged (1.8.19). The 2.x line ships only as
# `v2.0.0-beta.N` GitHub prereleases, so GitHub's "latest" release still
# points at 1.8.19. This rebuilds nixpkgs' AppImage wrapper around the release
# pinned in pin.json next to this file; nixpkgs binds its src in a `let`, so
# it can't be swapped with `override`.
#
# If nixpkgs has caught up past the pin, its own package wins, so a stale pin
# never downgrades Motrix. Nix's compareVersions ranks `2.0.0-beta.46` above
# `2.0.0`, so `-` becomes `.pre.` first: `pre` sorts below everything,
# putting every prerelease before its release.
#
# `update_system` refreshes the pin before every rebuild. To refresh it on its
# own, run `update_motrix` (optionally with a version such as `2.0.0-beta.46`)
# and rebuild.
self: super: let
  pname = "motrix";
  pin = super.lib.importJSON ./pin.json;
  inherit (pin) version;

  semverKey = super.lib.replaceStrings ["-"] [".pre."];

  src = super.fetchurl {
    url = "https://github.com/agalwood/Motrix/releases/download/v${version}/Motrix-${version}-x86_64.AppImage";
    inherit (pin) hash;
  };

  appimageContents = super.appimageTools.extract {inherit pname version src;};

  pinned = super.appimageTools.wrapType2 {
    inherit pname version src;

    # The desktop entry starts `AppRun`; the wrapper is `motrix`.
    extraInstallCommands = ''
      install -Dm444 ${appimageContents}/motrix.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/motrix.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=motrix'
      cp -r --no-preserve=mode ${appimageContents}/usr/share/icons $out/share/icons
    '';

    meta = {
      description = "Full-featured download manager (upstream AppImage)";
      homepage = "https://motrix.app";
      license = super.lib.licenses.mit;
      sourceProvenance = [super.lib.sourceTypes.binaryNativeCode];
      mainProgram = "motrix";
      platforms = ["x86_64-linux"];
    };
  };
in {
  motrix =
    if super.lib.versionOlder (semverKey super.motrix.version) (semverKey version)
    then pinned
    else super.motrix;
}
