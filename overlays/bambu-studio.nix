# Bambu Studio — Bambu Lab's slicer, wrapped from the official release
# AppImage. nixpkgs' `bambu-studio` source build is unfree, so Hydra never
# caches it (every bump is a long local compile) and it trails upstream
# releases. This exposes a separate `bambu-studio-bin` attr rather than
# replacing `bambu-studio`, because nixpkgs builds `orca-slicer` on top of it.
#
# The AppImage bundles its own wxWidgets, OpenSSL and ffmpeg but links the
# host's GTK3, WebKitGTK 4.1 and GStreamer; appimageTools' FHS env covers all
# of those except WebKitGTK, which extraPkgs adds.
#
# To bump, take the newest non-beta tag and its Ubuntu 24.04 asset name from
#   gh release list -R bambulab/BambuStudio
#   gh release view v<version> -R bambulab/BambuStudio --json assets -q '.assets[].name'
# then set `version` and `build` (the timestamp in the asset name) and refresh
# the hash with
#   nix store prefetch-file https://github.com/bambulab/BambuStudio/releases/download/v<version>/BambuStudio_ubuntu24.04-v<version>-<build>.AppImage
self: super: let
  pname = "bambu-studio";
  version = "02.08.02.61";
  build = "20260820225108";

  src = super.fetchurl {
    url = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/BambuStudio_ubuntu24.04-v${version}-${build}.AppImage";
    hash = "sha256-1QGxA/rFQkUT7A6Na8FF+zBxneLH2U1zINcjdAyBp/0=";
  };

  appimageContents = super.appimageTools.extract {inherit pname version src;};
in {
  bambu-studio-bin = super.appimageTools.wrapType2 {
    inherit pname version src;

    extraPkgs = pkgs: [
      pkgs.webkitgtk_4_1
      pkgs.glib-networking
      pkgs.gst_all_1.gst-plugins-good
      pkgs.gst_all_1.gst-plugins-bad
      pkgs.gst_all_1.gst-libav
    ];

    # - GDK_BACKEND=x11: upstream only supports X11 (its own Flathub build
    #   grants just the X11 socket) and the wxWidgets GL canvas misbehaves
    #   under native Wayland, so run it through Xwayland.
    # - SSL_CERT_FILE: the bundled OpenSSL looks for a Debian CA path; point it
    #   at the host bundle (bambulab/BambuStudio#6013).
    # - GIO_EXTRA_MODULES: GLib only searches its own store path and the
    #   session's modules, so the login WebView reports "TLS support is not
    #   available" until it can load glib-networking's libgiognutls from the
    #   FHS env.
    # - WEBKIT_*: the login WebView's OAuth callback fails with DMA-BUF
    #   compositing, same workaround nixpkgs applies (NixOS/nixpkgs#498307).
    profile = ''
      export GDK_BACKEND=x11
      export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
      export GIO_EXTRA_MODULES=/usr/lib64/gio/modules''${GIO_EXTRA_MODULES:+:$GIO_EXTRA_MODULES}
      export WEBKIT_DISABLE_COMPOSITING_MODE=1
      export WEBKIT_DISABLE_DMABUF_RENDERER=1
    '';

    # The AppImage's entry runs `AppRun`; the wrapper is `bambu-studio`.
    extraInstallCommands = ''
      install -Dm444 ${appimageContents}/BambuStudio.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/BambuStudio.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=${pname}'
      cp -r --no-preserve=mode ${appimageContents}/usr/share/icons $out/share/icons
    '';

    meta = {
      description = "PC software for Bambu Lab 3D printers (upstream AppImage)";
      homepage = "https://github.com/bambulab/BambuStudio";
      license = super.lib.licenses.agpl3Plus;
      sourceProvenance = [super.lib.sourceTypes.binaryNativeCode];
      mainProgram = pname;
      platforms = ["x86_64-linux"];
    };
  };
}
