{inputs, ...}: {
  nixpkgs.overlays = [
    inputs.catppuccin-vsc.overlays.default
    (import ../../../overlays/mpv-mpris.nix)
    (import ../../../overlays/openldap.nix)
  ];
}
