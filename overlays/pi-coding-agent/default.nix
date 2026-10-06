# Pi coding agent — tracks the newest upstream GitHub release instead of
# whatever nixpkgs last merged. nixpkgs' package already builds the monorepo
# from source with buildNpmPackage, so this overlay only swaps in the release
# pinned in pin.json next to this file; the build, wrapper (ripgrep, fd,
# PI_SKIP_VERSION_CHECK, PI_TELEMETRY) and version check stay nixpkgs'.
#
# A release needs three hashes: the source tarball, its npm dependency cache
# and the matching @earendil-works/pi-ai tarball that supplies the provider
# model catalog. buildNpmPackage derives `npmDeps` from its arguments rather
# than from finalAttrs, so `npmDeps` is rebuilt here instead of overriding
# `npmDepsHash`.
#
# If nixpkgs has caught up past the pin, its own package wins, so a stale pin
# never downgrades pi.
#
# `update_system` refreshes the pin before every rebuild. To refresh it on its
# own, run `update_pi_coding_agent` (optionally with a version such as
# `1.0.4`) and rebuild.
self: super: let
  pin = super.lib.importJSON ./pin.json;
  inherit (pin) version;

  pinned = super.pi-coding-agent.overrideAttrs (final: _prev: {
    inherit version;

    src = super.fetchFromGitHub {
      owner = "earendil-works";
      repo = "pi";
      tag = "v${version}";
      inherit (pin) hash;
    };

    npmDeps = super.fetchNpmDeps {
      inherit (final) src;
      name = "${final.pname}-${version}-npm-deps";
      hash = pin.npmDepsHash;
    };

    modelData = super.fetchurl {
      url = "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-${version}.tgz";
      hash = pin.modelDataHash;
    };
  });
in {
  pi-coding-agent =
    if super.lib.versionOlder super.pi-coding-agent.version version
    then pinned
    else super.pi-coding-agent;
}
