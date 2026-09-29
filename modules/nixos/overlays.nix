# Overlays every host needs. Host-local overlay lists (e.g.
# hosts/whopper/modules/overlays.nix) append to this one.
{...}: {
  nixpkgs.overlays = [
    (import ../../overlays/claude-code)
  ];
}
