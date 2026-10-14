# MacFlurry's nix-darwin modules: the shared Mac baseline (modules/darwin)
# plus what only MacFlurry has.
{...}: {
  imports = [
    ../../../modules/darwin
    ./homebrew.nix
  ];

  networking.hostName = "MacFlurry";

  system.stateVersion = 7;
}
