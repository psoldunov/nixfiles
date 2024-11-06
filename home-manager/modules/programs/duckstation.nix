{pkgs, ...}: {
  home.file = {
    "/home/psoldunov/.local/share/duckstation/bios" = {
      target = "/mnt/Games/Emulation/Settings/DuckStation/bios";
    };
  };
}
