# Per-host knobs for BigTasty. Threaded into every module via specialArgs
# as `hostConfig`. Schema mirrors hosts/whopper/hostConfig.nix; flags
# default to false on Whopper, true here where the server uses them.
#
# Schema:
#   role :: "desktop" | "server"
#
#   enableHyprland          :: bool  (desktop session toggle)
#   ollamaDocker            :: bool  (containerised Ollama vs native)
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
#
#   obsidianBase            :: path  (root of Obsidian vaults, host-specific)
{
  role = "server";

  obsidianBase = "/RAID/apps/syncthing/Obsidian";

  enableHyprland = false;
  ollamaDocker = false;

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
