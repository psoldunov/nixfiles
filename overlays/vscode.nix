self: super: {
  vscode = super.vscode.overrideAttrs (oldAttrs: {
    nativeBuildInputs = oldAttrs.nativeBuildInputs or [] ++ [self.makeWrapper];
    postInstall =
      oldAttrs.postInstall
      or ""
      + ''
        wrapProgram $out/bin/code --set LD_LIBRARY_PATH "${self.stdenv.cc.cc.lib}/lib/"
      '';
  });
}
