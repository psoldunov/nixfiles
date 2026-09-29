{inputs, ...}: {
  nixpkgs.overlays = [
    inputs.catppuccin-vsc.overlays.default
    # Adds `ensemblr` (release AppImage) and `ensemblr-master` (built from
    # the pinned master commit). Both install as `ensemblr`; install only one.
    inputs.ensemblr.overlays.default
    (import ../../../overlays/mpv-mpris.nix)
    (import ../../../overlays/openldap.nix)
    (import ../../../overlays/vapor-kde.nix)
    (import ../../../overlays/duckstation.nix)
    (import ../../../overlays/bambu-studio.nix)
    (import ../../../overlays/solaar.nix {src = inputs.solaar;})
  ];
}
