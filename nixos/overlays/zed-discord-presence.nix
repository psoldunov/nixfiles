self: super: {
  zed-discord-presence = super.stdenv.mkDerivation rec {
    pname = "zed-discord-presence";
    version = "0.7.0";

    # Helper functions for choosing the correct architecture and platform.
    arch =
      if super.stdenv.system == "x86_64-linux"
      then "x86_64-unknown-linux-gnu"
      else if super.stdenv.system == "x86_64-darwin"
      then "x86_64-apple-darwin"
      else if super.stdenv.system == "aarch64-darwin"
      then "aarch64-apple-darwin"
      # Extend further platforms if needed here.
      else throw "Unsupported platform: ${super.stdenv.system}";

    # Dynamic selection of the tarball based on the architecture/platform.
    src = super.fetchurl {
      url = "https://github.com/xhyrom/zed-discord-presence/releases/download/v${version}/discord-presence-lsp-${arch}.tar.gz";
      # Update `sha256` based on architecture-specific tarballs.
      sha256 =
        if super.stdenv.system == "x86_64-linux"
        then "sha256-QiHo4euR5sbI5P4yAhcQAE9rJl88b2eYt0fZPiPE18E="
        else if super.stdenv.system == "x86_64-darwin"
        then "03p6h2ls3687f73533yx7mc8imnb2bjdxg50006ycn9i9a6b76p6"
        else if super.stdenv.system == "aarch64-darwin"
        then "0ig15kbavjlxa9777yxa4kcbmp0akh8fjkfd7crdc2pjdf2zy5gp"
        else throw "Unsupported platform: ${super.stdenv.system}";
    };

    nativeBuildInputs = with super; [
      autoPatchelfHook
    ];

    buildInputs = with super; [
      openssl
      libgcc
    ];

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      install -m755 -D discord-presence-lsp-${arch}/discord-presence-lsp $out/bin/discord-presence-lsp
      runHook postInstall
    '';

    meta = {
      description = "A language server that handles hover information in package.json files";
      homepage = "https://github.com/xhyrom/zed-discord-presence";
      platforms = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    };
  };
}
