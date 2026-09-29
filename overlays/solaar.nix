# Solaar built from master of psoldunov/Solaar, a fork of pwr-Solaar/Solaar
# that carries fixes not yet released upstream. It replaces nixpkgs' `solaar`
# in place, so `programs.solaar`, `hardware.logitech.wireless` and
# `logitech-udev-rules` (the package's `udev` output) all pick up the fork.
#
# `src` is the `solaar` flake input, pinned in flake.lock. To take the newest
# commit on the fork's master:
#   nix flake update solaar
# nixpkgs' build (dependencies, udev output, tests) is reused as is; only the
# source and version change.
{src}: self: super: let
  baseVersion = super.lib.fileContents "${src}/lib/solaar/version";
  # lastModifiedDate is YYYYMMDDhhmmss; nixpkgs spells it YYYY-MM-DD.
  date = src.lastModifiedDate;
  year = builtins.substring 0 4 date;
  month = builtins.substring 4 2 date;
  day = builtins.substring 6 2 date;
  version = "${baseVersion}-unstable-${year}-${month}-${day}";
in {
  solaar = super.solaar.overridePythonAttrs (old: {
    inherit src version;

    # setup.py records `git describe` in lib/solaar/commit, and Solaar shows
    # that as its version. The flake input has no .git, so write the same
    # shape here; `solaar --version` then names the fork commit it runs.
    postPatch =
      (old.postPatch or "")
      + ''
        echo "${baseVersion}-g${src.shortRev}" > lib/solaar/commit
      '';

    # nixpkgs builds the changelog URL from `src.tag`, which a flake input
    # does not have.
    meta =
      old.meta
      // {
        homepage = "https://github.com/psoldunov/Solaar";
        changelog = "https://github.com/psoldunov/Solaar/commits/${src.rev}";
      };
  });
}
