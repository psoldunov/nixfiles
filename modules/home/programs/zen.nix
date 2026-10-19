# Zen Browser from youwen5/zen-browser-flake, for the Linux desktops
# (Whopper and ShackStack). The Macs get it from the Homebrew cask
# (modules/darwin/homebrew.nix).
{
  inputs,
  pkgs,
  ...
}: let
  zen = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system};
  # zen-browser-flake's bot hashed 1.23.3b before Zen published the release
  # (youwen5/zen-browser-flake#22). The hash below is GitHub's digest of the
  # published asset. Applies to 1.23.3b only, so the next version bump drops
  # it on its own.
  zen-unwrapped =
    if zen.zen-browser-unwrapped.version == "1.23.3b"
    then
      zen.zen-browser-unwrapped.overrideAttrs {
        src = pkgs.fetchurl {
          url = "https://github.com/zen-browser/desktop/releases/download/1.23.3b/zen.linux-x86_64.tar.xz";
          hash = "sha256-uyBF0+IWVNQP6EElAJLurf0sH8gx7vtQkiJ3PIvcoUk=";
        };
      }
    else zen.zen-browser-unwrapped;
in {
  home.packages = [
    (zen.default.override {zen-browser-unwrapped = zen-unwrapped;})
  ];
}
