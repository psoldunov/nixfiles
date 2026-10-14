# Whopper's tweaks on top of the shared Ghostty config
# (modules/home/workstation/ghostty.nix): a smaller font for its display and
# a less see-through background. The Macs keep the shared values.
{lib, ...}: {
  programs.ghostty.settings = {
    font-size = lib.mkForce 11.5;
    background-opacity = lib.mkForce 0.8;
  };
}
