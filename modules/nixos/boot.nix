# Host-agnostic boot baseline: systemd-boot loader, EFI variable access,
# and mdadm/swraid monitoring. Plymouth, kernelParams, and host-specific
# kernel modules live in each host's boot.nix.
{...}: {
  boot.loader.systemd-boot.enable = true;
  # /boot is a 511M ESP; each generation copies its own kernel + initrd,
  # so an unbounded menu fills it and the bootloader install fails (ENOSPC).
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.swraid = {
    enable = true;
    # Space-separated form per mdadm.conf(5). Whopper previously had the
    # `MAILADDR=` form which is invalid syntax — moving here normalises.
    mdadmConf = ''
      MAILADDR philipp@theswisscheese.com
    '';
  };
}
