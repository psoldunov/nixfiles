# shortcut: since nixpkgs#537108 the cargo setup hook exports
# AWS_LC_SYS_USE_SYSTEM, LIBSQLITE3_SYS_USE_PKG_CONFIG and friends, so crates
# link system libraries instead of building their own. codex 0.167.0 lists
# none of them, and aws-lc-sys stops the build. Adds the four nixpkgs#584667
# adds. Drop once that PR reaches nixos-unstable and a flake update pulls it in.
final: prev: {
  codex = prev.codex.overrideAttrs (old: {
    buildInputs =
      old.buildInputs
      ++ [
        prev.aws-lc
        prev.oniguruma
        prev.sqlite
        prev.zstd
      ];
  });
}
