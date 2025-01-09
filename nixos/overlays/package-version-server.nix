self: super: {
  package-version-server = super.stdenv.mkDerivation rec {
    pname = "package-version-server";
    version = "0.0.7";

    src = super.fetchurl {
      url = "https://github.com/zed-industries/package-version-server/releases/download/v${version}/package-version-server-x86_64-unknown-linux-gnu.tar.gz";
      sha256 = "sha256-dHeM9e6sjvvOzcBoAyAZ60ELfy51q/ZEI6TN8yZY1FU=";
    };

    nativeBuildInputs = [
      super.autoPatchelfHook
    ];

    buildInputs = [
      super.openssl # Provides libssl.so.3 and libcrypto.so.3
      super.gcc.lib # Provides libgcc_s.so.1
    ];

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      install -m755 -D package-version-server $out/bin/package-version-server
      runHook postInstall
    '';

    meta = {
      description = "A language server that handles hover information in package.json files";
      homepage = "https://github.com/zed-industries/package-version-server";
      platforms = ["x86_64-linux"];
    };
  };
}
