{pkgs, ...}: {
  home.file = {
    "/home/psoldunov/.local/share/duckstation/bios" = {
      path = "/mnt/Games/Emulation/Settings/DuckStation/bios";
    };
  };
}
