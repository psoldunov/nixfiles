# The convert_all_to_webp script text from modules/home/workstation/scripts.nix,
# evaluated against a stub pkgs (no builds). ImageMagick is the string "FAKE",
# which test_convert_all_to_webp.py swaps for a fake `magick`.
{flake}: let
  lib = flake.inputs.nixpkgs.lib;
  pkgs = {
    stdenv.hostPlatform.isDarwin = false;
    writeShellScriptBin = name: text: {inherit name text;};
    imagemagick = "FAKE";
  };
  mod = import "${flake}/modules/home/workstation/scripts.nix" {
    inherit lib pkgs;
    config = {};
    osConfig = {};
  };
in
  (lib.findFirst (p: p.name == "convert_all_to_webp") null mod.home.packages).text
