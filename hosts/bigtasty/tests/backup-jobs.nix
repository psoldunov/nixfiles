# BigTasty backup job options and rendered scripts, as test_backup_jobs.py reads them.
# `flake` is the flake's outputs (`self`, or `builtins.getFlake` standalone).
# Reading ExecStart realises the two tiny job scripts while this is evaluated.
{flake}: let
  c = flake.nixosConfigurations.BigTasty.config;
  job = n: {
    type = c.systemd.services.${n}.serviceConfig.Type or "simple";
    restart = c.systemd.services.${n}.serviceConfig.Restart or null;
    wantedBy = c.systemd.services.${n}.wantedBy;
    mounts = c.systemd.services.${n}.unitConfig.RequiresMountsFor or [];
    path = c.systemd.services.${n}.environment.PATH;
    script = builtins.readFile c.systemd.services.${n}.serviceConfig.ExecStart;
    timer = c.systemd.timers.${n}.timerConfig or {};
    timerWantedBy = c.systemd.timers.${n}.wantedBy or [];
  };
in {
  jobs = {
    immichSync = job "immichSync";
    sharesSync = job "sharesSync";
  };
  immichVolumes = c.virtualisation.oci-containers.containers.immich_server.volumes;
  postgresVolumes = c.virtualisation.oci-containers.containers.immich_postgres.volumes;
}
