self: super: {
  package-version-server = super.stdenv.mkDerivation rec {
    pname = "package-version-server";
    version = "0.0.7";

    src = super.fetchurl {
      url = "https://github.com/zed-industries/package-version-server/releases/download/v${version}/package-version-server-x86_64-unknown-linux-gnu.tar.gz";
      sha256 = "sha256-dHeM9e6sjvvOzcBoAyAZ60ELfy51q/ZEI6TN8yZY1FU=";
    };

    nativeBuildInputs = [super.patchelf]; # For patching the binary
    buildInputs = [super.glibc super.zlib]; # Dependencies for runtime (adjust as needed)

    # Explicit unpackPhase since the tarball contains only a single binary
    unpackPhase = ''
      mkdir source
      cd source
      tar -xzf "$src" # Extract the tarball into the "source" directory
      ls -al .
    '';

    installPhase = ''
      mkdir -p $out/bin

      # Move the binary to $out/bin
      mv source/* $out/bin/

      # Patch the binary with NixOS's dynamic linker
      patchelf --set-interpreter "$(cat ${super.glibc}/nix-support/dynamic-linker)" \
               --set-rpath "${super.glibc}/lib:${super.zlib}/lib" \
               $out/bin/package-version-server
    '';

    meta = {
      description = "A language server that handles hover information in package.json files";
      homepage = "https://github.com/zed-industries/package-version-server";
      platforms = ["x86_64-linux"];
    };
  };
}
