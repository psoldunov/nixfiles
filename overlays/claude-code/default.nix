# Claude Code — tracks Anthropic's `latest` release channel instead of
# whatever nixpkgs last merged. nixpkgs' package already builds from the
# native binary on downloads.claude.ai and takes the release manifest as a
# `manifest` argument, so this overlay only swaps in the manifest pinned next
# to it; the wrapper, runtime deps and version check stay nixpkgs'.
#
# If nixpkgs has caught up past the pinned manifest, its own package wins,
# so a stale pin never downgrades Claude Code.
#
# `update_system` refreshes the pin before every flake update. To refresh it
# on its own, run `update_claude_code` (optionally with a version) and
# rebuild.
self: super: let
  manifest = super.lib.importJSON ./manifest.zst.json;
in {
  claude-code =
    if super.lib.versionOlder super.claude-code.version manifest.version
    then super.claude-code.override {inherit manifest;}
    else super.claude-code;
}
