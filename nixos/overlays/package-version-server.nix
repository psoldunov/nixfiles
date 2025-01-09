self: super: {
  package-version-server = super.stdenv.mkDerivation rec {
    pname = "package-version-server";
    version = "0.0.7";

    src = super.fetchurl {
      url = "https://github.com/zed-industries/package-version-server/releases/download/v${version}/package-version-server-x86_64-unknown-linux-gnu.tar.gz";
      sha256 = "sha256-dHeM9e6sjvvOzcBoAyAZ60ELfy51q/ZEI6TN8yZY1FU=";
    };

    nativeBuildInputs = [super.patchelf]; # For patching the binary
    buildInputs = [super.glibc super.zlib]; # Add likely shared library dependencies

    # Explicit unpackPhase since tarball doesn't create directories
    unpackPhase = ''
      mkdir source
      cd source
      tar -xzf "$src"
    '';

    # installPhase wraps the binary
    installPhase = ''
      mkdir -p $out/bin

      # Move the binary into $out/bin
      mv source/* $out/bin/package-version-server

      # Use patchelf to set the runtime dynamic linker and rpath
      patchelf --set-interpreter "$(cat ${super.glibc}/nix-support/dynamic-linker)" \
               --set-rpath "${super.glibc}/lib:${super.zlib}/lib" \
               $out/bin/package-version-server

      # Optionally wrap the binary to ensure necessary environment variables
      wrapProgram $out/bin/package-version-server \
        --set LD_LIBRARY_PATH "${super.glibc}/lib:${super.zlib}/lib"
    '';

    meta = {
      description = "A language server that handles hover information in package.json files";
      homepage = "https://github.com/zed-industries/package-version-server";
      platforms = ["x86_64-linux"];
    };
  };
}
