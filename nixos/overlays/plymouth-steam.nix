self: super: {
  plymouth-steam = super.stdenv.mkDerivation rec {
    pname = "plymouth-steam";
    version = "0.1";

    src = super.fetchurl {
      url = "https://github.com/MrVivekRajan/Plymouth-Themes/releases/download/steam/Steam.tar.gz";
      sha256 = "1frvjhv7hjc1jr16p35vxzg27sa286k9pvdc7cgzsr6fw8xnygkm";
    };

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/plymouth/themes/steam
      cp Steam/* $out/share/plymouth/themes/steam
      substituteInPlace $out/share/plymouth/themes/steam/Steam.plymouth \
        --replace-fail "/usr/" "$out/"
      runHook postInstall
    '';
  };
}
