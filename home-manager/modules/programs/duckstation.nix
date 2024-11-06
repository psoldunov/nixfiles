{pkgs, ...}: {
  home.file = {
    "/home/psoldunov/.local/share/duckstation/bios" = {
      source = "/mnt/Games/Emulation/Settings/DuckStation/bios";
    };
  };
}
