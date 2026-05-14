# Container + VM baseline. Watchtower is the only OCI container shared
# by every host; everything else (ollama, transmission, slskd, immich,
# …) lives in the host's virtualisation module and merges into
# `oci-containers.containers` by key.
{...}: {
  virtualisation = {
    docker.enable = true;
    docker.enableOnBoot = true;
    libvirtd.enable = true;
    containerd.enable = true;
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers.watchtower = {
      image = "nickfedor/watchtower:latest";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
      environment = {
        TZ = "Asia/Nicosia";
        WATCHTOWER_SCHEDULE = "0 0 4 * * *";
        WATCHTOWER_CLEANUP = "true";
      };
    };
  };
}
