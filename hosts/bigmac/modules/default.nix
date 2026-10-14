# BigMac's nix-darwin modules: the shared Mac baseline (modules/darwin)
# plus what only BigMac has.
{...}: {
  imports = [
    ../../../modules/darwin
    ./homebrew.nix
  ];

  networking.hostName = "BigMac";

  system.stateVersion = 7;
}
