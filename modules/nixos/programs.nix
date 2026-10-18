# Everyday-CLI baseline. Everything here was previously duplicated across
# both hosts. The shells are in ./shell.nix.
{...}: {
  programs.mtr.enable = true;
  programs.git = {
    enable = true;
    lfs.enable = true;
  };

  services.iperf3 = {
    enable = true;
    openFirewall = true;
  };
}
