# Vapor — the SteamOS Plasma 6 global theme by Valve (a dark BreezeDark variant).
# Not in nixpkgs; it ships inside SteamOS's prebuilt `steamdeck-kde-presets`
# package. We fetch that archive and extract only the theming bits:
#   - plasma/look-and-feel/com.valve.vapor*.desktop  (the global themes)
#   - plasma/desktoptheme/Vapor                       (the Plasma style)
#   - color-schemes/Vapor.colors                      (the color scheme)
#   - konsole/Vapor.*                                 (matching Konsole profile)
# Install the package (system or home) so Plasma finds it via XDG_DATA_DIRS,
# then select look-and-feel "com.valve.vapor.desktop".
self: super: {
  vapor-kde-theme = super.stdenvNoCC.mkDerivation {
    pname = "vapor-kde-theme";
    version = "0.29";

    src = super.fetchurl {
      url = "https://steamdeck-packages.steamos.cloud/archlinux-mirror/jupiter-main/os/x86_64/steamdeck-kde-presets-0.29-1-any.pkg.tar.zst";
      hash = "sha256-xvI4CeTs8KRKv12YKd2z7vtzPzag/OL26Uki5jpOWg8=";
    };

    nativeBuildInputs = [super.zstd];
    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      mkdir -p extracted $out/share
      tar --use-compress-program=unzstd -xf "$src" -C extracted
      cp -r extracted/usr/share/plasma        $out/share/plasma
      cp -r extracted/usr/share/color-schemes $out/share/color-schemes
      cp -r extracted/usr/share/konsole       $out/share/konsole
      runHook postInstall
    '';

    meta = {
      description = "Vapor — SteamOS global theme for KDE Plasma 6 (BreezeDark variant by Valve)";
      license = super.lib.licenses.gpl2Plus;
      platforms = super.lib.platforms.linux;
    };
  };
}
