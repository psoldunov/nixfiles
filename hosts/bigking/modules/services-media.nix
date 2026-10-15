# Plex, in place of ADM's Plex app. Its library database lives in
# /var/lib/plex on the NVMe mirror; ./INSTALL.md copies ADM's over from
# /volume1/Plex/Library. Library paths stay /volume1/..., as under ADM.
{...}: {
  services.plex = {
    enable = true;
    openFirewall = true;
  };

  # /dev/dri for hardware transcoding.
  users.users.plex.extraGroups = ["video" "render"];

  # With the array missing, Plex would find every item gone and empty its
  # trash after the next scan.
  systemd.services.plex.unitConfig.RequiresMountsFor = ["/volume1"];
}
