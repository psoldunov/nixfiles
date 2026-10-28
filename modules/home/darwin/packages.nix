# The Macs' CLI tools on top of modules/home/workstation/cli.nix: the ones
# they used to take from Homebrew, now from nixpkgs. Agent CLIs and tap-only
# formulae stay in Homebrew (modules/darwin/homebrew.nix).
{pkgs, ...}: {
  home.packages = with pkgs; [
    _7zz
    actionlint
    age
    bitwarden-cli
    cmatrix
    # g-prefixed (gls, gdate), so macOS's own ls and date keep their names.
    coreutils-prefixed
    # The GNU tools macOS has no command for go on PATH unprefixed too.
    (linkFarm "coreutils-unshadowed" (map (n: {
      name = "bin/${n}";
      path = "${coreutils}/bin/${n}";
    }) ["nproc" "numfmt" "shuf" "tac" "timeout"]))
    fd
    ghostscript
    git-filter-repo
    jdk
    mactop
    # `brew bundle check` needs it to see the App Store apps.
    mas
    mongosh
    ninja
    periphery
    poppler-utils
    potrace
    prettier
    pv
    qpdf
    resvg
    supabase-cli
    swiftlint
    zellij
  ];
}
