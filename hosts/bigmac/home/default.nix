# BigMac's home-manager config: the shared modules and the workstation layer
# make shell, Claude Code and pi the same as on Whopper; modules/home/darwin
# adds what every Mac shares.
{...}: {
  imports = [
    ../../../modules/home
    ../../../modules/home/workstation
    ../../../modules/home/darwin
  ];

  home.stateVersion = "25.11";
}
