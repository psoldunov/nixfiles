# BigTasty's overlays on top of modules/nixos/overlays.nix: the agent tools
# its T3 Code server runs, pinned to the versions Whopper runs.
{...}: {
  nixpkgs.overlays = [
    (import ../../../overlays/t3code)
    (import ../../../overlays/pi-coding-agent)
  ];
}
