# Codex from upstream's release package instead of nixpkgs' source build,
# which compiled codex for the better part of an hour on Whopper and on
# BigTasty, and again on every nixpkgs bump. Upstream's x86_64 musl package
# is static and runs as is; it carries its own rg, bwrap and voice host in
# the layout codex-package.json describes, so bin/codex is not wrapped.
# Only the voice host links glibc, and autoPatchelfHook points it at Nix's.
#
# The Macs install codex from Homebrew (modules/darwin/homebrew.nix).
#
# `update_system` refreshes pin.json before every rebuild. To refresh it on
# its own, run `update_codex` (optionally with a version such as `0.167.0`)
# and rebuild.
final: prev: let
  pin = prev.lib.importJSON ./pin.json;
in {
  codex =
    if prev.stdenv.hostPlatform.system != "x86_64-linux"
    then prev.codex
    else
      prev.stdenv.mkDerivation {
        pname = "codex";
        inherit (pin) version;

        src = prev.fetchurl {
          url = "https://github.com/openai/codex/releases/download/rust-v${pin.version}/codex-package-x86_64-unknown-linux-musl.tar.zst";
          inherit (pin) hash;
        };
        # The archive holds bin/, codex-path/ and codex-resources/ side by side.
        sourceRoot = ".";

        nativeBuildInputs = [prev.autoPatchelfHook prev.installShellFiles prev.zstd];

        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp -r bin codex-path codex-resources codex-package.json $out/
          installShellCompletion --cmd codex \
            --bash <($out/bin/codex completion bash) \
            --fish <($out/bin/codex completion fish) \
            --zsh <($out/bin/codex completion zsh)
          runHook postInstall
        '';

        # Upstream ships stripped binaries; leave them byte for byte.
        dontStrip = true;

        meta =
          prev.codex.meta
          // {
            platforms = ["x86_64-linux"];
            sourceProvenance = [prev.lib.sourceTypes.binaryNativeCode];
          };
      };
}
