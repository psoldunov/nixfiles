# fish/mtr/git/iperf3 live in modules/nixos/programs.nix.
{...}: {
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
