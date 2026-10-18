# Per-host knobs for PiHome. Threaded into its Home Manager modules via
# extraSpecialArgs as `hostConfig`. Schema in hosts/bigtasty/hostConfig.nix;
# only `role` is read (by modules/home/shell), the flags are informational.
{
  role = "server";

  enableRaid = false;
  enableNfsServer = false;
  enableSambaShares = false;
  enableNetatalk = false;
  enableMediaStack = false;
  enableArrStack = false;
  enableNginxVhosts = false;
  enableCloudflareTunnels = false;
  enableDyndns = false;
  enableDockerOci = false;
}
