# Shell + everyday-CLI baseline. Everything here was previously
# duplicated across both hosts.
{...}: {
  programs.fish.enable = true;
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
