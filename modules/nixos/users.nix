# Baseline psoldunov account. Hosts append extra groups, ssh keys,
# `linger`, etc. — `extraGroups` is a list type so values concat across
# modules. The login shell is set in ./shell.nix.
{...}: {
  users.users.psoldunov = {
    isNormalUser = true;
    description = "Philipp Soldunov";
    extraGroups = ["wheel" "docker" "libvirtd" "video"];
    # The same list the Macs accept (modules/darwin/system.nix).
    openssh.authorizedKeys.keys = (import ../../lib/ssh-keys.nix).authorized;
  };
}
