# The overlays BigMac needs: the two agents that track upstream releases
# instead of nixpkgs (modules/nixos/overlays.nix carries the same claude-code
# overlay for the NixOS hosts), plus macOS build fixes.
{...}: {
  nixpkgs.overlays = [
    (import ../../../overlays/claude-code)
    (import ../../../overlays/pi-coding-agent)
    # nixos-unstable moves on Linux results, so Hydra's aarch64-darwin builds
    # can lag behind it and BigMac compiles the gap itself. atuin's test
    # suite segfaults on macOS (history_delete, SIGSEGV), so build it
    # without the tests. Leaf package: nothing else links it.
    (_final: prev: {
      atuin = prev.atuin.overrideAttrs {doCheck = false;};
    })
  ];
}
