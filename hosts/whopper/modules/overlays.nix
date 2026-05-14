{inputs, ...}: {
  nixpkgs.overlays = [
    inputs.catppuccin-vsc.overlays.default
    inputs.millennium.overlays.default
    (import ../../../overlays/hyprevents.nix)
    (import ../../../overlays/pedro-raccoon-plymouth.nix)
    (import ../../../overlays/mpv-mpris.nix)
    (import ../../../overlays/openldap.nix)
  ];
}
