{pkgs, ...}: {
  users.users.psoldunov = {
    isNormalUser = true;
    description = "Philipp Soldunov";
    extraGroups = ["networkmanager" "docker" "disk" "wheel" "i2c" "video" "storage" "libvirtd" "scanner" "lp" "input"];
    shell = pkgs.fish;
  };

  system.stateVersion = "23.11";
}
