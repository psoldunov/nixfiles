# Numero — Numi-style text calculator in Rust and GPUI, from its own flake.
# The package installs the `numero-app` window, the `numero` terminal
# calculator, the dev.soldunov.numero desktop entry and the icons. It builds
# from source: the first rebuild after a bump compiles the whole workspace.
# Bump it with `nix flake update numero`.
#
# The numero:// handler lives in hosts/whopper/mime-defaults.nix.
{
  inputs,
  pkgs,
  ...
}: {
  home.packages = [
    inputs.numero.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
