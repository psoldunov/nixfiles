# Ensemblr — the desktop orchestrator for Pi and Claude Code, from its own
# AppImage release. The project ships no flake and no source build: the release
# is an electron-builder AppImage, so it is wrapped rather than rebuilt.
#
# wrapType2 keeps the AppImage whole and runs it inside an FHS environment,
# which is what the bundled Electron expects. The desktop entry and the icons
# are copied out of the extracted image so the launcher finds them; `Exec` is
# rewritten because the entry inside the image calls `Ensemblr`, the name the
# AppImage has when it is a loose file, and this wrapper is on PATH as
# `ensemblr`.
#
# To take a new release: bump `version`, then
#   nix store prefetch-file --name Ensemblr-<version>-x64.AppImage \
#     https://github.com/ensemblr-hq/ensemblr/releases/download/v<version>/Ensemblr-<version>-x64.AppImage
# and put the hash it prints in `hash`.
self: super: let
  pname = "ensemblr";
  version = "0.1.22";

  src = super.fetchurl {
    url = "https://github.com/ensemblr-hq/ensemblr/releases/download/v${version}/Ensemblr-${version}-x64.AppImage";
    hash = "sha256-iezTqtfp8onm/8dAKGpbg3w2xM+n9GoHM0o9noWUerE=";
  };

  contents = super.appimageTools.extract {inherit pname version src;};
in {
  ensemblr = super.appimageTools.wrapType2 {
    inherit pname version src;

    # Every stream of work gets its own git worktree, so git has to be inside
    # the FHS environment as well as on the host.
    extraPkgs = pkgs: [pkgs.git];

    extraInstallCommands = ''
      install -Dm644 ${contents}/${pname}.desktop \
        $out/share/applications/${pname}.desktop
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace-fail "Exec=Ensemblr" "Exec=${pname}"
      cp -r ${contents}/usr/share/icons $out/share/icons
    '';

    meta = {
      description = "Desktop orchestrator for Pi and Claude Code, one git worktree per stream of work";
      homepage = "https://github.com/ensemblr-hq/ensemblr";
      changelog = "https://github.com/ensemblr-hq/ensemblr/blob/v${version}/CHANGELOG.md";
      license = super.lib.licenses.asl20;
      platforms = ["x86_64-linux"];
      sourceProvenance = [super.lib.sourceTypes.binaryNativeCode];
      mainProgram = pname;
    };
  };
}
