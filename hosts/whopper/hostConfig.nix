# Per-host knobs for Whopper. Threaded into every module via specialArgs
# as `hostConfig`. Schema is shared with hosts/bigtasty/hostConfig.nix.
# Server flags default to false here; modules gate on them via
# `lib.mkIf hostConfig.<flag>`.
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
  role = "desktop";

  obsidianBase = "/home/psoldunov/Documents/Obsidian";

  enableHyprland = true;
  ollamaDocker = false;

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
