# MacFlurry's home-manager config: the same as BigMac's. The shared modules
# and the workstation layer match Whopper; modules/home/darwin adds what
# every Mac shares.
{...}: {
  imports = [
    ../../../modules/home
    ../../../modules/home/workstation
    ../../../modules/home/darwin
  ];

  home.stateVersion = "25.11";
}
