{
  pkgs,
  appleFonts,
  ...
}: {
  fonts.enableDefaultPackages = true;
  fonts.fontconfig = {
    enable = true;
    useEmbeddedBitmaps = true;
    defaultFonts.emoji = [
      "Noto Color Emoji"
    ];
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
