# Baseline psoldunov account lives in modules/nixos/users.nix.
{...}: {
  # psoldunov's ADM uid, and the uid the NFS clients write as, so what it
  # owns on /volume1 stays its own. Its group is `users` (gid 100) on both.
  users.users.psoldunov.uid = 1000;

  # ADM's built-in admin (uid 999, group administrators gid 999) owns most
  # of /volume1. Declaring both keeps NixOS from handing 999 to a system
  # user of its own, which would then appear to own the shares.
  users.users.admin = {
    uid = 999;
    group = "administrators";
    isSystemUser = true;
  };

  users.groups.administrators = {
    gid = 999;
    members = ["psoldunov"];
  };
}
