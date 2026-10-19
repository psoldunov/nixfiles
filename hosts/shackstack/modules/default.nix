# ShackStack-local NixOS modules. The shared baseline (boot loader, locale,
# nix settings, users, openssh, sops preamble, graphics) comes from
# ../../../modules/nixos; ./overrides.nix turns off the parts of it an HTPC
# has no use for.
{...}: {
  imports = [
    ../../../modules/nixos

    ./access.nix
    ./boot.nix
    ./desktop.nix
    ./game-mode.nix
    ./mounts.nix
    ./networking.nix
    ./overrides.nix
    ./tv-cec
  ];
}
