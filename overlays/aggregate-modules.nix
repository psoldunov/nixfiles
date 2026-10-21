# shortcut: since nixpkgs#571181, aggregateModules cats a .ko.cer certificate
# for every external kernel module and fails when one is missing. Packages
# that copy their .ko by hand instead of running kbuild's modules_install ship
# none (asustor-platform-driver, ddcci-driver, xpad-noone; nixpkgs#575192).
# Skip the missing ones, so those modules load unsigned as they did before.
# Drop once nixpkgs fixes the aggregator or those packages.
final: prev: {
  aggregateModules = modules:
    (prev.aggregateModules modules).overrideAttrs (old: let
      from = "| xargs -d'\\n' cat >> modules.cer";
      to = ''| while IFS= read -r f; do [ ! -e "$f" ] || cat -- "$f"; done >> modules.cer'';
    in {
      postBuild =
        if prev.lib.hasInfix from old.postBuild
        then builtins.replaceStrings [from] [to] old.postBuild
        else throw "overlays/aggregate-modules.nix: the aggregator changed upstream; check nixpkgs#575192 and drop this overlay";
    });
}
