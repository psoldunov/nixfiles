# T3 Code nightly — Theo's desktop app for coding agents, from the upstream
# nightly channel (`vX.Y.Z-nightly.YYYYMMDD.N` GitHub prereleases). nixpkgs'
# `t3code` builds the stable line from source, so this adds `t3code-nightly`
# beside it instead of overriding it. Both install as `t3code`; install only
# one.
#
# The AppImage bundles Electron and the resource-monitor sidecar. Agent CLIs
# (codex, claude, gh, git) come from the user's PATH, which the FHS env keeps.
#
# `t3code-server-nightly` is the headless server (`t3`) from the same
# release, for BigTasty. A desktop client and its server must speak the same
# protocol, so both read one pin: rebuild both hosts after it changes.
#
# `update_system` refreshes pin.json before every rebuild. To refresh it on
# its own, run `update_t3code` (optionally with a version such as
# `0.1.8-nightly.20261104.4165`) and rebuild.
self: super: let
  pname = "t3code";
  pin = super.lib.importJSON ./pin.json;
  inherit (pin) version;
  releaseUrl = "https://github.com/pingdotgg/t3code/releases/download/v${version}";

  src = super.fetchurl {
    url = "${releaseUrl}/T3-Code-${version}-x86_64.AppImage";
    inherit (pin) hash;
  };

  appimageContents = super.appimageTools.extract {inherit pname version src;};
in {
  # A Node single-executable application with the app injected into its ELF.
  # The fixup phase leaves it unpatched and unstripped; it runs through nix-ld
  # (every NixOS host, modules/nixos/nix.nix). It looks for client/ and
  # node_modules/ next to its real path, so the tree is copied whole.
  t3code-server-nightly = super.stdenvNoCC.mkDerivation {
    pname = "t3code-server";
    inherit version;

    src = super.fetchurl {
      url = "${releaseUrl}/t3-${version}-linux-x64.tar.gz";
      hash = pin.serverHash;
    };

    dontConfigure = true;
    dontBuild = true;
    dontPatchELF = true;
    dontStrip = true;

    installPhase = ''
      mkdir -p $out/lib $out/bin
      cp -r . $out/lib/t3code
      ln -s $out/lib/t3code/t3 $out/bin/t3
    '';

    meta = {
      description = "T3 Code server, nightly channel (upstream release archive)";
      homepage = "https://github.com/pingdotgg/t3code";
      license = super.lib.licenses.mit;
      sourceProvenance = [super.lib.sourceTypes.binaryNativeCode];
      mainProgram = "t3";
      platforms = ["x86_64-linux"];
    };
  };

  t3code-nightly = super.appimageTools.wrapType2 {
    inherit pname version src;

    # The desktop entry starts `AppRun`; the wrapper is `t3code`.
    extraInstallCommands = ''
      install -Dm444 ${appimageContents}/t3code.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/t3code.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=${pname}'
      cp -r --no-preserve=mode ${appimageContents}/usr/share/icons $out/share/icons
    '';

    meta = {
      description = "Desktop app for coding agents, nightly channel (upstream AppImage)";
      homepage = "https://github.com/pingdotgg/t3code";
      license = super.lib.licenses.mit;
      sourceProvenance = [super.lib.sourceTypes.binaryNativeCode];
      mainProgram = pname;
      platforms = ["x86_64-linux"];
    };
  };
}
