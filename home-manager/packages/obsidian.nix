{pkgs ? import <nixpkgs> {}}: let
  version = "1.6.3";
  filename = "obsidian-${version}.tar.gz";

  obsidian = pkgs.obsidian.overrideAttrs (oldAttrs: {
    src = pkgs.fetchurl {
      url = "https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/${filename}";
      sha256 = "ho8E2Iq+s/w8NjmxzZo/y5aj3MNgbyvIGjk3nSKPLDw=";
    };
    version = version;
  });
in
  obsidian
