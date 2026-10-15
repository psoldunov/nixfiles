# Per-host knobs for BigKing. Threaded into every module via specialArgs
# as `hostConfig`. Schema in hosts/bigtasty/hostConfig.nix; only `role` is
# read (by modules/home/shell/shell.nix), the flags are informational.
{
  role = "server";

  enableRaid = true;
  enableNfsServer = true;
  enableSambaShares = true;
  enableNetatalk = false;
  enableMediaStack = true;
  enableArrStack = false;
  enableNginxVhosts = false;
  enableCloudflareTunnels = false;
  enableDyndns = false;
  enableDockerOci = false;
}
