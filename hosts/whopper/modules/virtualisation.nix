# Docker/libvirtd/containerd baseline + watchtower live in
# modules/nixos/virtualisation.nix. Whopper adds desktop-only USB
# redirection, virt-manager, and the portainer agent container.
{...}: {
  virtualisation.spiceUSBRedirection.enable = true;

  programs.virt-manager.enable = true;

  virtualisation.oci-containers.containers = {
    agent = {
      image = "portainer/agent:2.19.5";
      ports = [
        "9001:9001"
      ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "/var/lib/docker/volumes:/var/lib/docker/volumes"
      ];
    };
  };
}
