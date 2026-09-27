{inputs, ...}: {
  nixpkgs.overlays = [
    inputs.catppuccin-vsc.overlays.default
    (import ../../../overlays/ensemblr.nix)
    (import ../../../overlays/mpv-mpris.nix)
    (import ../../../overlays/openldap.nix)
    (import ../../../overlays/vapor-kde.nix)
  ];
}
