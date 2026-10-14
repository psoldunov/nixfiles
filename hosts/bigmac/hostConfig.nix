# Per-host knobs for BigMac (macOS on Apple silicon, nix-darwin). Threaded
# into every module via specialArgs as `hostConfig`. Schema is shared with
# hosts/whopper/hostConfig.nix. The server flags only mean something to
# NixOS modules and stay false here; shared home modules tell macOS from
# Linux with `pkgs.stdenv.hostPlatform.isDarwin`, not with a flag.
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
  role = "desktop";

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
