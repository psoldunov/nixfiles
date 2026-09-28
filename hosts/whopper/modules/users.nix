# Baseline psoldunov account + system.stateVersion live in
# modules/nixos. Whopper just appends desktop-specific groups.
{...}: {
  users.users.psoldunov.extraGroups = [
    "networkmanager"
    "disk"
    "i2c"
    "storage"
    "scanner"
    "lp"
    "input"
    # /dev/uinput, for deckmaster's key emulation (hardware.uinput in ./hardware.nix).
    "uinput"
    "librepods"
  ];
}
