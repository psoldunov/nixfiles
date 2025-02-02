self: super: {
  pedro-raccoon-plymouth = super.stdenv.mkDerivation rec {
    pname = "pedro-raccoon-plymouth";
    version = "1.1";

    src = super.fetchFromGitHub {
      owner = "FilaCo";
      repo = "pedro-raccoon-plymouth";
      rev = "01ff1f4";
      hash = "sha256-L+jfH2edHN6kqqjpAesRr317ih3r4peGklRwvziksHE=";
    };

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/plymouth/themes/pedro-raccoon
      cp pedro-raccoon/* $out/share/plymouth/themes/pedro-raccoon
      substituteInPlace $out/share/plymouth/themes/pedro-raccoon/pedro-raccoon.plymouth \
        --replace-fail "/usr/" "$out/"
      runHook postInstall
    '';

    passthru.updateScript = super.unstableGitUpdater {};

    meta = {
      description = "This is a simple Plymouth theme with Pedro racoon meme.";
      homepage = "https://github.com/FilaCo/pedro-raccoon-plymouth";
      license = super.lib.licenses.mit;
      platforms = super.lib.platforms.linux;
    };
  };
}
