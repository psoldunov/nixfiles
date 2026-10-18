# mtr/git/iperf3 live in modules/nixos/programs.nix, zsh and fish in
# modules/nixos/shell.nix.
{...}: {
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
