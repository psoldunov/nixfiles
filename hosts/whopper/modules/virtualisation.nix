# Docker/libvirtd/containerd baseline + watchtower live in
# modules/nixos/virtualisation.nix. Whopper adds desktop-only USB
# redirection, virt-manager, and its AMD-accelerated containers.
{
  lib,
  hostConfig,
  ...
}: {
  virtualisation.spiceUSBRedirection.enable = true;

  programs.virt-manager.enable = true;

  virtualisation.oci-containers.containers = {
    ollama = lib.mkIf hostConfig.ollamaDocker {
      image = "ollama/ollama:rocm";
      ports = ["11434:11434"];
      extraOptions = [
        "--device=/dev/dri:/dev/dri"
        "--device=/dev/kfd:/dev/kfd"
      ];
      environment = {
        HSA_OVERRIDE_GFX_VERSION = "11.0.0";
        OLLAMA_ORIGINS = "app://obsidian.md*";
        OLLAMA_GPU_OVERHEAD = "2147483648";
        OLLAMA_KEEP_ALIVE = "1m";
      };
      volumes = [
        "/var/lib/private/ollama:/root/.ollama"
      ];
    };
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
