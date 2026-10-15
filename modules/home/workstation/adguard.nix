# Workstations operate both DNS servers over SSH, PiHome first, then
# BigTasty's standby; API credentials stay on the servers.
{pkgs, ...}: {
  home.packages = [
    (pkgs.callPackage ../../../packages/adguard-cli {
      config = {
        mode = "remote";
        targets = ["pihome" "bigtasty"];
      };
    })
  ];
}
