# Parts of the shared baseline an HTPC has no use for.
{lib, ...}: {
  # modules/nixos/virtualisation.nix turns on docker, libvirtd, containerd and
  # a watchtower container on every host. Nothing here runs containers or
  # VMs, so all of it is off, together with its daily image prune.
  virtualisation = {
    docker.enable = lib.mkForce false;
    libvirtd.enable = lib.mkForce false;
    containerd.enable = lib.mkForce false;
    oci-containers.containers = lib.mkForce {};
  };
  systemd.services.docker-image-prune.enable = false;
  systemd.timers.docker-image-prune.enable = false;

  # The baseline account joins docker and libvirtd, which do not exist here.
  users.users.psoldunov.extraGroups = lib.mkForce ["wheel" "video" "networkmanager"];
}
