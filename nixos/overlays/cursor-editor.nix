final: prev: {
  cursor-editor = let
    pname = "cursor";
    version = "0.42.0";
    src = final.fetchurl {
      url = "https://downloader.cursor.sh/linux/appImage/x64";
      hash = "sha256-CD6bQ4T8DhJidiOxNRgRDL4obfEZx7hnO0VotVb6lDc=";
    };
    appimageContents = final.appimageTools.extract {inherit pname version src;};
  in
    final.appimageTools.wrapType2 {
      inherit pname version src;
      extraInstallCommands = ''
        install -m 444 -D ${appimageContents}/${pname}.desktop -t $out/share/applications
        substituteInPlace $out/share/applications/${pname}.desktop \
          --replace-quiet 'Exec=AppRun' 'Exec=${pname}'
        cp -r ${appimageContents}/usr/share/icons $out/share
        # Ensure the binary exists and create a symlink if it doesn't already exist
        if [ -e ${appimageContents}/AppRun ]; then
          install -m 755 -D ${appimageContents}/AppRun $out/bin/${pname}-${version}
          if [ ! -L $out/bin/${pname} ]; then
            ln -s $out/bin/${pname}-${version} $out/bin/${pname}
          fi
        else
          echo "Error: Binary not found in extracted AppImage contents."
          exit 1
        fi
      '';
      extraBwrapArgs = [
        "--bind-try /etc/nixos/ /etc/nixos/"
      ];
      dieWithParent = false;
      extraPkgs = pkgs:
        with final; [
          unzip
          autoPatchelfHook
          asar
          (buildPackages.wrapGAppsHook.override {inherit (buildPackages) makeWrapper;})
        ];
    };
}
