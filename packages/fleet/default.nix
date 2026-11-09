# fleet: the workstations' CLI for rebuilding, updating, cleaning, rebooting,
# suspending and waking the hosts, with a report of every run that can be
# handed to an agent. Stdlib Python; ./fleet runs as a directory, so its
# modules import each other. `config` (hosts, pins, gum) comes from
# modules/home/workstation/scripts.nix.
{
  lib,
  python3,
  writeShellScriptBin,
  config,
}:
writeShellScriptBin "fleet" ''
  exec ${python3}/bin/python3 ${./fleet} ${lib.escapeShellArg (builtins.toJSON config)} "$@"
''
