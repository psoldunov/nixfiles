# Per-host knobs for BigTasty. Threaded into every module via specialArgs
# as `hostConfig`. Schema mirrors hosts/whopper/hostConfig.nix; flags
# default to false on Whopper, true here where the server uses them.
#
# Schema:
#   role :: "desktop" | "server"
#
#   enableRaid              :: bool  (mdadm + /RAID fileSystems)
#   enableNfsServer         :: bool  (NFS server exports)
#   enableSambaShares       :: bool  (Samba + samba-wsdd)
#   enableNetatalk          :: bool  (AFP shares)
#   enableMediaStack        :: bool  (jellyfin + uptime-kuma)
#   enableArrStack          :: bool  (sonarr/radarr/lidarr/prowlarr/jellyseerr)
#   enableNginxVhosts       :: bool  (nginx + ACME)
#   enableCloudflareTunnels :: bool  (cloudflared tunnels)
#   enableDyndns            :: bool  (cloudflare-dyndns)
#   enableDockerOci         :: bool  (virtualisation.oci-containers)
{
  role = "server";

  enableRaid = true;
  enableNfsServer = true;
  enableSambaShares = true;
  enableNetatalk = true;
  enableMediaStack = true;
  enableArrStack = true;
  enableNginxVhosts = true;
  enableCloudflareTunnels = true;
  enableDyndns = true;
  enableDockerOci = true;
}
