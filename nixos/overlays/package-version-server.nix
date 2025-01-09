self: super: {
  package-version-server = super.stdenv.mkDerivation rec {
    pname = "package-version-server";
    version = "0.0.7";

    src = super.fetchurl {
      url = "https://github.com/zed-industries/package-version-server/releases/download/v${version}/package-version-server-x86_64-unknown-linux-gnu.tar.gz";
      sha256 = "sha256-dHeM9e6sjvvOzcBoAyAZ60ELfy51q/ZEI6TN8yZY1FU=";
    };

    nativeBuildInputs = [super.patchelf]; # For patching dynamic linker
    buildInputs = [super.glibc super.zlib]; # Shared libraries

    # Unpack the tarball (include debug output for clarity)
    unpackPhase = ''
      mkdir source
      cd source
      tar -xzf "$src"

      # Debug: Check tarball contents
      echo "Unpacked tarball contents:"
      ls -al
    '';

    # Install binary with runtime dependencies
    installPhase = ''
      mkdir -p $out/bin

      # Find the binary dynamically
      binary=$(find . -type f -name "package-version-server")
      if [ -z "$binary" ]; then
        echo "Error: 'package-version-server' binary not found! Listing contents:"
        ls -al
        exit 1
      fi

      # Move the binary into $out/bin
      mv "$binary" $out/bin/package-version-server

      # Set dynamic linker and runtime paths
      patchelf --set-interpreter "$(cat ${super.glibc}/nix-support/dynamic-linker)" \
               --set-rpath "${super.glibc}/lib:${super.zlib}/lib" \
               $out/bin/package-version-server

      # Wrap binary to ensure runtime environment
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
