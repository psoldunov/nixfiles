self: super: {
  zed-editor = super.zed-editor.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs ++ [super.zlib];

    # Ensure zlib is available at runtime as well
    postFixup =
      (oldAttrs.postFixup or "")
      + super.lib.optionalString super.stdenv.hostPlatform.isLinux ''
        patchelf --add-rpath ${super.zlib}/lib $out/libexec/*
      '';
  });

  # Also apply the same changes to the FHS version
  zed-editor-fhs = super.zed-editor-fhs.override {
    zed-editor = self.zed-editor;
  };
}
