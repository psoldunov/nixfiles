self: super: {
  figma-linux = super.figma-linux.overrideAttrs (oldAttrs: {
    postInstall = ''
      wrapProgram $out/bin/figma-linux \
        --set LD_LIBRARY_PATH /run/opengl-driver/lib \
        --add-flags "--enable-features=UseOzonePlatform --ozone-platform-hint=auto"
    '';
  });
}
