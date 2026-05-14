{pkgs, ...}: {
  users.users.psoldunov = {
    isNormalUser = true;
    shell = pkgs.fish;
    description = "Philipp Soldunov";
    extraGroups = ["wheel" "docker" "libvirtd" "video" "media"];
    packages = with pkgs; [];
  };

  users.extraUsers.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
  };

  users.groups = {
    media = {
      gid = 1777;
      members = [];
    };
    cloudflared = {};
  };
}
