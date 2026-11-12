# Keep overlays to leaf packages. Overriding a shared library changes the
# hash of everything that links it, so none of that comes from
# cache.nixos.org any more: `openldap.doCheck = false` once made every rebuild
# compile all of Plasma, gnupg, libvirt and fwupd locally.
{inputs, ...}: {
  nixpkgs.overlays = [
    inputs.catppuccin-vsc.overlays.default
    # Adds `ensemblr` (release AppImage) and `ensemblr-master` (built from
    # the pinned master commit). Both install as `ensemblr`; install only one.
    inputs.ensemblr.overlays.default
    (import ../../../overlays/discord.nix)
    (import ../../../overlays/mpv-mpris.nix)
    (import ../../../overlays/vapor-kde.nix)
    (import ../../../overlays/duckstation)
    (import ../../../overlays/motrix)
    (import ../../../overlays/pi-coding-agent)
    (import ../../../overlays/bambu-studio.nix)
    (import ../../../overlays/periphery.nix)
    (import ../../../overlays/solaar.nix {src = inputs.solaar;})
  ];
}
