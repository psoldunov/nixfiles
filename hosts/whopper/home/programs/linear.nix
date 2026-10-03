# Linear — Linux rebuild of Linear's desktop client, from its own flake. The
# flake builds against nixpkgs' Electron 43 and installs a `linear` binary, a
# desktop entry, and icons. Bump it with `nix flake update linear`.
#
# The package is unfree, but the flake's `packages` output allows it on its
# own, so no allowUnfree entry is needed here. The linear:// handler lives in
# hosts/whopper/mime-defaults.nix; sign-in through the browser needs it.
{
  inputs,
  pkgs,
  ...
}: let
  upstream = inputs.linear.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # The package names its icon `linear-desktop` and installs it in hicolor.
  # Plasma shows Breeze's `linear` action icon (a white ramp) instead:
  # KIconLoader strips dash suffixes inside the active theme before it falls
  # back to hicolor, so `linear-desktop` resolves to Breeze's `linear` first.
  # Re-export the icons under a dashless name the installed themes lack and
  # point the desktop entry at it. Drop this wrapper once the upstream flake
  # renames its icon.
  iconName = "lineardesktop";

  linear = pkgs.symlinkJoin {
    inherit (upstream) name;
    paths = [upstream];
    postBuild = ''
      for icon in ${upstream}/share/icons/hicolor/*/apps/linear-desktop.png; do
        size=$(basename "$(dirname "$(dirname "$icon")")")
        ln -s "$icon" "$out/share/icons/hicolor/$size/apps/${iconName}.png"
      done

      desktop=share/applications/linear.desktop
      rm "$out/$desktop"
      substitute "${upstream}/$desktop" "$out/$desktop" \
        --replace-fail "Icon=linear-desktop" "Icon=${iconName}"
    '';
  };
in {
  home.packages = [linear];
}
