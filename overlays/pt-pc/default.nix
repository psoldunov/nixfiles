# P.T. PC port — LoreanXavier's native Vulkan port of the 2014 PS4 teaser.
# It reads every level, model, texture and sound at run time from the
# player's own copy of the game, so the package holds no game data. Upstream
# builds Linux binaries for glibc distros only: `pt` loads Vulkan, X11 and
# Wayland, PipeWire/PulseAudio/ALSA, udev and curl with dlopen, and the fPKG
# extractor beside it is a self-contained .NET app. We unpack the portable
# release and patch every ELF in it for NixOS.
#
# The game keeps pt.ini, saves, logs and its texture cache in data/ beside
# the executable, which it finds through /proc/self/exe, so it can't run from
# the store. `pt-pc` keeps a per-user install in $XDG_DATA_HOME/pt-pc: a copy
# of `pt`, links to the rest of the runtime, and the player's own data/,
# mods/ and CUSA01127/ (the three archives extracted from the PKG; the
# first-run screen extracts them when the folder is missing). The in-game
# update check is off: the pin is the version.
#
# Pinned (version + hash in pin.json next to this file). `update_system`
# refreshes the pin before every rebuild. To refresh it on its own, run
# `update_pt_pc` (optionally with a version such as `1.0.5`) and rebuild.
self: super: let
  inherit (super) lib;
  pname = "pt-pc";
  pin = lib.importJSON ./pin.json;
  inherit (pin) version;

  # Opened with dlopen by `pt` (SDL3, volk, the update check). SDL3 lists
  # its share in `.note.dlopen`, which autoPatchelf treats as hard
  # dependencies, so they are buildInputs as well as runtimeDependencies.
  dlopenLibs = with super; [
    vulkan-loader
    libGL
    libx11
    libxcursor
    libxext
    libxfixes
    libxi
    libxrandr
    libxscrnsaver
    libxtst
    libxkbcommon
    wayland
    libdecor
    pipewire
    libpulseaudio
    alsa-lib
    udev
    libusb1
    curl
  ];

  runtime = super.stdenv.mkDerivation {
    pname = "${pname}-runtime";
    inherit version;

    src = super.fetchurl {
      url = "https://github.com/LoreanXavier/pt-pc/releases/download/v${version}/P.T.PC.Port-portable-linux.zip";
      name = "pt-pc-portable-linux-${version}.zip";
      inherit (pin) hash;
    };

    nativeBuildInputs = [super.unzip super.autoPatchelfHook];
    # libstdc++, libgcc_s and libgomp for .NET and Real-ESRGAN, which links
    # libvulkan like FidelityFX does.
    buildInputs = [super.stdenv.cc.cc.lib] ++ dlopenLibs;
    # autoPatchelf adds these to the RUNPATH of the executables only; curl
    # has no `.note.dlopen` entry.
    runtimeDependencies = map lib.getLib dlopenLibs;
    # .NET's native shims dlopen ICU and OpenSSL themselves, and dlopen
    # searches the RUNPATH of the library that calls it, not the program's.
    appendRunpaths = map (p: "${lib.getLib p}/lib") [super.icu super.openssl];
    autoPatchelfIgnoreMissingDeps = [
      # .NET's LTTng tracing provider; the runtime starts without it.
      "liblttng-ust.so.0"
      # SDL3's PowerVR GLES 1 and Steam user storage backends.
      "libGLES_CM.so.1"
      "libsteam_api.so"
    ];

    dontConfigure = true;
    dontBuild = true;
    # The strip hook runs on every file, and binutils strips .NET's PE
    # assemblies too, which CoreCLR then refuses to load.
    stripExclude = ["lib/pt-pc/extractor/*"];

    # The zip stores no execute bits.
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib
      cp -r . $out/lib/pt-pc
      chmod +x $out/lib/pt-pc/{pt,pt-updater} \
        $out/lib/pt-pc/texture-tools/realesrgan-ncnn-vulkan \
        $out/lib/pt-pc/extractor/{PT.PkgExtract,createdump}
      runHook postInstall
    '';
  };

  launcher = super.writeShellApplication {
    name = pname;
    runtimeInputs = [super.coreutils super.findutils];
    text = ''
      runtime=${runtime}/lib/pt-pc
      root=''${XDG_DATA_HOME:-$HOME/.local/share}/pt-pc
      mkdir -p "$root"

      if [ ! -x "$root/pt" ] || [ "$(cat "$root/.runtime" 2>/dev/null)" != "$runtime" ]; then
        # Links into an older runtime go first, so files a release no
        # longer ships don't linger.
        find "$root" -mindepth 1 -maxdepth 1 -type l -lname '/nix/store/*' -delete
        for entry in "$runtime"/*; do
          name=''${entry##*/}
          if [ "$name" != pt ]; then
            ln -sfnT "$entry" "$root/$name"
          fi
        done
        # A copy, not a link: the game takes its folder from /proc/self/exe.
        install -m 755 "$runtime/pt" "$root/.pt.tmp"
        mv -f "$root/.pt.tmp" "$root/pt"
        printf '%s\n' "$runtime" > "$root/.runtime"
      fi

      # SDL takes the Wayland app_id and the X11 WM_CLASS from SDL_APP_ID;
      # matching the desktop entry gives the window its icon in Plasma.
      export SDL_APP_ID=${pname}
      cd "$root"
      exec "$root/pt" --no-update-check "$@"
    '';
  };

  # The port's own icon (MIT, assets/pt.ico), from the v1.0.5 tag's commit.
  icon = super.fetchurl {
    url = "https://raw.githubusercontent.com/LoreanXavier/pt-pc/60fe8b324aca24c264e89378ae0d2c61f3a674af/assets/pt.ico";
    name = "pt-pc-icon.ico";
    hash = "sha256-R9iYDm+/Xn/UrEZMuRXwtbdqZkO5zGvYHwswI1n/nyY=";
  };
in {
  pt-pc = super.stdenvNoCC.mkDerivation {
    inherit pname version;
    dontUnpack = true;

    nativeBuildInputs = [super.copyDesktopItems super.icoutils];

    desktopItems = [
      (super.makeDesktopItem {
        name = pname;
        desktopName = "P.T.";
        comment = "Native PC port of the 2014 PS4 teaser, played from your own game files";
        exec = pname;
        icon = pname;
        categories = ["Game"];
        startupWMClass = pname;
      })
    ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      ln -s ${launcher}/bin/${pname} $out/bin/${pname}
      # 16 to 256 px, all 32-bit (icotool's --bit-depth filter matches none).
      icotool -x -o . ${icon}
      for png in *.png; do
        [[ $png =~ _([0-9]+x[0-9]+)x[0-9]+\.png$ ]]
        install -Dm444 "$png" $out/share/icons/hicolor/''${BASH_REMATCH[1]}/apps/${pname}.png
      done
      test -f $out/share/icons/hicolor/256x256/apps/${pname}.png
      runHook postInstall
    '';

    passthru = {inherit runtime;};

    meta = {
      description = "Native PC port of P.T., played from your own PS4 game files (upstream binaries)";
      homepage = "https://github.com/LoreanXavier/pt-pc";
      # The port is MIT; the bundled DLSS runtime is under NVIDIA's RTX SDK
      # license.
      license = with lib.licenses; [mit unfreeRedistributable];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      mainProgram = pname;
      platforms = ["x86_64-linux"];
    };
  };
}
