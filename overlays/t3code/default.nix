# T3 Code nightly — Theo's desktop app for coding agents, from the upstream
# nightly channel (`vX.Y.Z-nightly.YYYYMMDD.N` GitHub prereleases). nixpkgs'
# `t3code` builds the stable line from source, so this adds `t3code-nightly`
# beside it instead of overriding it. Both install as `t3code`; install only
# one.
#
# The AppImage bundles Electron and the resource-monitor sidecar. Agent CLIs
# (codex, claude, gh, git) come from the user's PATH, which the FHS env keeps.
#
# `update_system` refreshes pin.json before every rebuild. To refresh it on
# its own, run `update_t3code` (optionally with a version such as
# `0.1.8-nightly.20261104.4165`) and rebuild.
self: super: let
  pname = "t3code";
  pin = super.lib.importJSON ./pin.json;
  inherit (pin) version;

  src = super.fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
    inherit (pin) hash;
  };

  appimageContents = super.appimageTools.extract {inherit pname version src;};
in {
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
