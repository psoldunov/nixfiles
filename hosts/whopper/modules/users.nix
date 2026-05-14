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
  ];
}
