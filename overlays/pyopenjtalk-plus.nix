# shortcut: one pyopenjtalk-plus test matches an error message Cython 3.3
# reworded, so the package fails and takes piper-tts and calibre with it.
# Drop once nixpkgs#576063 lands.
final: prev: {
  pythonPackagesExtensions =
    prev.pythonPackagesExtensions
    ++ [
      (pyFinal: pyPrev: {
        pyopenjtalk-plus = pyPrev.pyopenjtalk-plus.overridePythonAttrs (old: {
          disabledTests =
            (old.disabledTests or [])
            ++ ["test_run_njd_from_mecab_invalid_input_should_not_break_next_call"];
        });
      })
    ];
}
