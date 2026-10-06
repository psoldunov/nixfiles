# Container + VM baseline. Watchtower is the only OCI container shared
# by every host; everything else (portainer agent, transmission, slskd,
# immich, …) lives in the host's virtualisation module and merges into
# `oci-containers.containers` by key. The daily image prune is shared too.
{config, ...}: {
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

  # Watchtower's cleanup only drops the image it just replaced. Images left
  # behind any other way (a container dropped from the config, a pinned tag
  # bumped) pile up, so prune every image no container uses once a day, an
  # hour after watchtower runs; Persistent catches up a run missed while the
  # machine was off. Images only: `virtualisation.docker.autoPrune` runs
  # `docker system prune`, which also removes unused networks and would
  # delete BigTasty's immich-network & co. from under a container that is
  # down at the time. `until=24h` spares an image pulled moments ago.
  systemd.services.docker-image-prune = {
    description = "Prune unused docker images";
    after = ["docker.service"];
    requires = ["docker.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.virtualisation.docker.package}/bin/docker image prune --all --force --filter until=24h";
    };
  };

  systemd.timers.docker-image-prune = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* 05:00:00";
      Persistent = true;
    };
  };
}
