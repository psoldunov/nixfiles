# Atuin on the Macs from upstream's release binary instead of a source
# build. Its test suite segfaults on these Macs (history_delete, SIGSEGV),
# and turning the tests off changes the hash, so cache.nixos.org never had
# our build and every nixpkgs bump compiled atuin on each Mac. The release
# binary links only macOS system libraries.
#
# It follows nixpkgs' atuin version. When nixpkgs moves to a version with no
# hash below, the Macs go back to building from source (tests off) and
# evaluation warns. To add the hash, run
#   nix store prefetch-file https://github.com/atuinsh/atuin/releases/download/v<version>/atuin-aarch64-apple-darwin.tar.gz
final: prev: let
  inherit (prev) lib;
  inherit (prev.atuin) version;
  hashes = {
    "18.23.0" = "sha256-yYi+HN4ZzXKVzmS8i5VdQvsYVeUifLZAyH/AnIQIw/w=";
  };
  fromSource = prev.atuin.overrideAttrs {doCheck = false;};
  fromRelease = prev.stdenvNoCC.mkDerivation {
    pname = "atuin";
    inherit version;
    src = prev.fetchurl {
      url = "https://github.com/atuinsh/atuin/releases/download/v${version}/atuin-aarch64-apple-darwin.tar.gz";
      hash = hashes.${version};
    };
    nativeBuildInputs = [prev.installShellFiles];
    installPhase = ''
      runHook preInstall
      install -Dm755 atuin $out/bin/atuin
      installShellCompletion --cmd atuin \
        --bash <($out/bin/atuin gen-completions -s bash) \
        --fish <($out/bin/atuin gen-completions -s fish) \
        --zsh <($out/bin/atuin gen-completions -s zsh)
      runHook postInstall
    '';
    # Stripping would break the binary's code signature.
    dontFixup = true;
    meta =
      prev.atuin.meta
      // {
        platforms = ["aarch64-darwin"];
        sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      };
  };
in {
  atuin =
    if prev.stdenv.hostPlatform.system == "aarch64-darwin" && hashes ? ${version}
    then fromRelease
    else
      lib.warnIf prev.stdenv.hostPlatform.isDarwin
      "overlays/atuin-darwin.nix has no release hash for atuin ${version}, so the Mac builds it from source"
      fromSource;
}
