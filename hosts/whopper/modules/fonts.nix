{
  pkgs,
  appleFonts,
  ...
}: {
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
}
