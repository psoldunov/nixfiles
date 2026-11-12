# BigTasty's overlays on top of modules/nixos/overlays.nix: the agent tools,
# pinned to the versions Whopper runs.
{...}: {
  nixpkgs.overlays = [
    (import ../../../overlays/pi-coding-agent)
  ];
}
