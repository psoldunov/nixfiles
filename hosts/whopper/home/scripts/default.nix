# Whopper-only shell scripts exposed on $PATH. The system scripts
# (rebuild_system, update_system, clean_system, the update_* pins) and the
# other portable helpers live in modules/home/workstation/scripts.nix.
{pkgs, ...}: let
  scripts = {
    kill_gamescope = pkgs.writeShellScriptBin "kill_gamescope" ''
      pkill -9 wine steam wineserver winedevice.exe explorer.exe gamescope plugplay.exe services.exe svchost.exe rpcss.exe .exe
    '';

    restart_steam = pkgs.writeShellScriptBin "restart_steam" ''
      pkill -9 steam && steam & disown
      exit 0
    '';
  };
in {
  home.packages = builtins.attrValues scripts;
}
