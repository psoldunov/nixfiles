# Per-host knobs for ShackStack. Threaded into every module via specialArgs
# as `hostConfig`. Schema in hosts/bigtasty/hostConfig.nix; only `role` is
# read (by modules/home/shell), the flags are informational.
#
# "htpc" is not "desktop" on purpose: the shell modules then leave out the
# workstation extras (Ghostty as $TERMINAL, dev PATH entries, the github and
# agency-vps keychain keys). This box runs games, not a dev setup.
{
  role = "htpc";

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
