{
  lib,
  python3,
  writeShellScriptBin,
  openssh,
  config ? {mode = "local";},
}: let
  cfg =
    config
    // lib.optionalAttrs ((config.mode or "local") == "remote") {
      ssh = "${openssh}/bin/ssh";
    };
  configJson = builtins.toJSON cfg;
  source = ./adguard.py;
in
  writeShellScriptBin "adguard" ''
    exec ${python3}/bin/python3 ${source} ${lib.escapeShellArg configJson} "$@"
  ''
