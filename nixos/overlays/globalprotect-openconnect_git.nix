self: super: {
  globalprotect-openconnect_git = super.stdenv.mkDerivation rec {
    pname = "globalprotect-openconnect";
    version = "2.3.4";

    src = super.fetchurl {
      url = "https://github.com/yuezk/GlobalProtect-openconnect/releases/download/v${version}/globalprotect-openconnect_${version}_x86_64.bin.tar.xz";
      sha256 = "03g7pvmvlmjrlj35cfqp4yj3k1f6jphc6kp283kj4q5ib3y58zrq";
    };

    nativeBuildInputs = with super; [
      autoconf
      automake
      pkg-config
      libtool
      makeWrapper
    ];

    buildInputs = with super; [
      openconnect
      webkitgtk
      libsecret
      libayatana-appindicator
    ];

    unpackPhase = ''
      tar -xJf ${src}
      cd globalprotect-openconnect_${version}
    '';

    patchPhase = ''
      sed -i 's|\\$(DESTDIR)/usr|\\$(DESTDIR)|g' Makefile
      cat Makefile
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      mkdir -p $out/share
      make install DESTDIR=$out
      runHook postInstall
    '';
  };
}
