# shortcut: speechd's rework (nixpkgs#470797) turned on strictDeps but left
# Python in buildInputs, so configure skips the Python bindings and calibre's
# speech test can't import `speechd`. Fixed for calibre's copy only: patching
# speechd itself would rebuild everything that links it (Firefox, Qt speech).
# Drop once nixpkgs#576062 lands.
final: prev: {
  calibre = prev.calibre.override {
    speechd-minimal = prev.speechd-minimal.overrideAttrs (old: {
      nativeBuildInputs = old.nativeBuildInputs ++ [prev.python3];
    });
  };
}
