# The overlays the Macs need: pi, which tracks upstream releases instead of
# nixpkgs, plus macOS build fixes. Claude Code comes from the
# claude-code@latest cask (modules/darwin/homebrew.nix), not overlays/claude-code.
{...}: {
  nixpkgs.overlays = [
    (import ../../overlays/pi-coding-agent)
    # Upstream's release binary, so no Mac compiles atuin.
    (import ../../overlays/atuin-darwin.nix)
    (_final: prev: {
      # nixpkgs builds this for Linux only. Upstream's configure handles
      # Darwin (it links a -bundle against the SDK's OpenPAM), so drop
      # linux-pam and allow the platform. Its /proc command-line lookup just
      # comes back empty here. Used by ./system.nix for ssh-agent sudo.
      pam_ssh_agent_auth = prev.pam_ssh_agent_auth.overrideAttrs (old: {
        buildInputs = builtins.filter (p: (p.pname or "") != "linux-pam") old.buildInputs;
        # Its bundled snprintf clashes with the SDK's fortify macros, and its
        # K&R-style openbsd-compat code predates C23, which autoconf would
        # otherwise pick for clang.
        hardeningDisable = (old.hardeningDisable or []) ++ ["fortify"];
        env = (old.env or {}) // {NIX_CFLAGS_COMPILE = "-D_FORTIFY_SOURCE=0";};
        preConfigure = (old.preConfigure or "") + "\nexport ac_cv_prog_cc_c23=no\n";
        meta = old.meta // {platforms = prev.lib.platforms.linux ++ prev.lib.platforms.darwin;};
      });
    })
  ];
}
