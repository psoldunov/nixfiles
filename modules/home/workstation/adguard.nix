# Workstations operate the Pi over SSH; API credentials stay on the Pi.
{pkgs, ...}: {
  home.packages = [
    (pkgs.callPackage ../../../packages/adguard-cli {
      config = {
        mode = "remote";
        target = "pihome";
      };
    })
  ];
}
