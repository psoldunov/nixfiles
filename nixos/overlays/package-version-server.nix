self: super: {
  package-version-server = super.stdenv.mkDerivation rec {
    pname = "package-version-server";
    version = "0.0.7";

    src = super.fetchurl {
      url = "https://github.com/zed-industries/package-version-server/releases/download/v${version}/package-version-server-x86_64-unknown-linux-gnu.tar.gz";
      sha256 = "sha256-dHeM9e6sjvvOzcBoAyAZ60ELfy51q/ZEI6TN8yZY1FU=";
    };

    # Explicit unpackPhase to handle tarball with no directory
    unpackPhase = ''
      mkdir source
      cd source
      tar -xzf "$src"
    '';

    # Updated installPhase to handle both single-file and multiple-file tarballs
    installPhase = ''
      mkdir -p $out/bin

      # Move files if there's one or more
      if [ -f * ]; then
        # Single binary directly in the tarball
        mv * $out/bin/
      elif [ "$(ls -A | wc -l)" -eq 0 ]; then
        echo "Error: No files found after unpacking tarball!"
        exit 1
      else
        # Handle other cases if needed
        echo "Unknown file structure! Listing unpacked contents:"
        ls -l
        exit 1
      fi
    '';

    meta = {
      description = "A language server that handles hover information in package.json files";
      homepage = "https://github.com/zed-industries/package-version-server";
      platforms = ["x86_64-linux"];
    };
  };
}
