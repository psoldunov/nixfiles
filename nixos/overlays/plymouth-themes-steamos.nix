self: super: {
  plymouth-themes-steamos = super.stdenv.mkDerivation rec {
    pname = "plymouth-themes-steamos";
    version = "1.1";

    src = super.fetchurl {
      url = "https://repo.steampowered.com/steamos/pool/main/p/plymouth-themes-steamos/plymouth-themes-steamos_0.17.tar.xz";
      sha256 = "0lwf1pv2qyja4pvhx3ayas9jxfq5arkvajzf94n36gsjami0kcs4";
    };

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/plymouth/themes/steamos
      cp usr/share/plymouth/themes/steamos/* $out/share/plymouth/themes/steamos
      substituteInPlace $out/share/plymouth/themes/steamos/steamos.plymouth \
        --replace-fail "/usr/" "$out/"
      runHook postInstall
    '';
  };
}
