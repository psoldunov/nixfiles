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
      patchelf
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
      substituteInPlace Makefile \
        --replace '$(DESTDIR)/usr/' $out/
      substituteInPlace artifacts/usr/share/applications/gpgui.desktop \
          --replace '/usr/bin/' $out/bin/
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      mkdir -p $out/share
      make install
      runHook postInstall

      # Move the original binaries
      mkdir -p $out/lib/globalprotect-openconnect
      for bin in gpauth gpclient gpgui gpgui-helper gpservice; do
        mv $out/bin/$bin $out/lib/globalprotect-openconnect/$bin
      done

      # Patch executables to use correct library paths
      for bin in $out/lib/globalprotect-openconnect/*; do
        patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
                --set-rpath ${super.lib.makeLibraryPath buildInputs} \
                $bin
      done

      # Create a temporary directory for symbolic links
      mkdir -p $out/symlink-bin
      for bin in gpauth gpclient gpgui gpgui-helper gpservice; do
        ln -s $out/lib/globalprotect-openconnect/$bin $out/symlink-bin/$bin
      done

      # Create a wrapper script for each binary
      for bin in gpauth gpclient gpgui gpgui-helper gpservice; do
        makeWrapper $out/lib/globalprotect-openconnect/$bin $out/bin/$bin \
          --prefix PATH : $out/symlink-bin \
          --prefix LD_LIBRARY_PATH : ${super.lib.makeLibraryPath buildInputs}
      done
    '';
  };

  myFhsEnv = super.buildFHSUserEnv {
    name = "globalprotect-openconnect-env";
    targetPkgs = pkgs: [
      pkgs.globalprotect-openconnect_git
      pkgs.openconnect
      pkgs.webkitgtk
      pkgs.libsecret
      pkgs.libayatana-appindicator
    ];

    runScript = ''
      export PATH=/usr/bin:$PATH
      exec /usr/bin/gpclient "$@"
    '';
  };
}
