# Docker/libvirtd/containerd baseline + watchtower live in
# modules/nixos/virtualisation.nix. Whopper adds desktop-only USB
# redirection, virt-manager, and its AMD-accelerated containers.
{...}: {
  virtualisation.spiceUSBRedirection.enable = true;

  programs.virt-manager.enable = true;

  virtualisation.oci-containers.containers = {
    whisper-rocm = {
      image = "psoldunov/openai-whisper-rocm:latest";
      extraOptions = [
        "--device=/dev/dri:/dev/dri"
        "--device=/dev/kfd:/dev/kfd"
      ];
      volumes = [
        "/home/psoldunov/.whisper:/data"
      ];
    };
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
