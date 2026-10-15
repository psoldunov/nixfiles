# Entry point for the BigKing host: the ASUSTOR Lockerstor 4 (AS6604T) NAS.
# Aggregates the NVMe layout, hardware and the NAS modules. Installing it
# over ADM is a one-off, described in ./INSTALL.md.
{...}: {
  imports = [
    ./disko.nix
    ./hardware.nix
    ./modules
  ];
}
