# Entry point for the BigTasty host. During the merge transition this
# re-exports the still-vendored monolithic configuration; Phase 4 will
# decompose it into focused modules under ./modules/.
{...}: {
  imports = [
    ../../vendor/server-import/nixos/configuration.nix
  ];
}
