# Baseline psoldunov account. Hosts append extra groups, ssh keys,
# `linger`, etc. — `extraGroups` is a list type so values concat across
# modules.
{pkgs, ...}: {
  users.users.psoldunov = {
    isNormalUser = true;
    description = "Philipp Soldunov";
    shell = pkgs.fish;
    extraGroups = ["wheel" "docker" "libvirtd" "video"];
    # The same list the Macs accept (modules/darwin/system.nix).
    openssh.authorizedKeys.keys = (import ../../lib/ssh-keys.nix).authorized;
  };
}
