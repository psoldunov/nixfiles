{
  config,
  pkgs,
  appleFonts,
  ...
}: let
  # Flatpak sandboxes cannot see /nix/store paths. bubblewrap only exposes the
  # host's FHS font directories (/usr/share/fonts, /usr/local/share/fonts,
  # ~/.local/share/fonts) as /run/host/{fonts,local-fonts,user-fonts}, which is
  # what the runtime's fontconfig scans. NixOS has none of those, so sandboxed
  # apps fall back to the runtime's handful of fonts and render tofu.
  #
  # Collapse every system font package into one tree and bind-mount it at
  # /usr/local/share/fonts so Flatpak picks it up as /run/host/local-fonts.
  aggregatedFonts = pkgs.buildEnv {
    name = "system-fonts";
    paths = config.fonts.packages;
    pathsToLink = ["/share/fonts"];
  };
in {
  fonts.enableDefaultPackages = true;
  fonts.fontconfig = {
    enable = true;
    useEmbeddedBitmaps = true;
    defaultFonts = {
      # SF Pro Display is the system UI face (see the plasma-manager `fonts`
      # block in home/desktop/plasma.nix). Mirroring it here makes apps that
      # resolve the generic `sans-serif` alias — GTK, Electron, browsers —
      # match the Plasma desktop instead of falling back to DejaVu Sans.
      sansSerif = [
        "SF Pro Display"
        "SF Pro Text"
        "Noto Sans"
      ];
      serif = [
        "New York"
        "Noto Serif"
      ];
      emoji = [
        "Noto Color Emoji"
      ];
    };
  };
  fonts.packages = with pkgs; [
    roboto
    openmoji-color
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    comic-neue
    comic-mono
    ibm-plex
    appleFonts.sf-pro
    appleFonts.sf-compact
    appleFonts.sf-mono
    appleFonts.sf-arabic
    appleFonts.ny
    nerd-fonts.jetbrains-mono
  ];

  # bindfs (FUSE) rather than a plain bind mount so the symlink farm produced
  # by buildEnv is resolved into real files — bubblewrap cannot follow links
  # that point back into /nix/store.
  system.fsPackages = [pkgs.bindfs];
  fileSystems."/usr/local/share/fonts" = {
    device = "${aggregatedFonts}/share/fonts";
    fsType = "fuse.bindfs";
    options = ["ro" "resolve-symlinks" "x-gvfs-hide"];
  };
}
