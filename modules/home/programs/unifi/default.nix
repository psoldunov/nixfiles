{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.unifi-readonly;
  adapter = pkgs.writers.writePython3Bin "unifi-readonly-adapter" {
    flakeIgnore = ["E501" "W503"];
    libraries = [pkgs.python3Packages.mcp pkgs.python3Packages.urllib3];
  } (builtins.readFile ./unifi_readonly.py);
  wrapper = pkgs.writeShellScriptBin "unifi-readonly" ''
    export UNIFI_API_KEY_FILE=${lib.escapeShellArg config.sops.secrets.UNIFI_API_KEY.path}
    ${lib.optionalString (cfg.caFile != null) "export UNIFI_CA_FILE=${lib.escapeShellArg cfg.caFile}"}
    ${lib.optionalString (cfg.pinnedCertificate != null) "export UNIFI_PINNED_CERTIFICATE=${lib.escapeShellArg "${cfg.pinnedCertificate}"}"}
    exec ${lib.getExe adapter} "$@"
  '';
in {
  options.programs.unifi-readonly = {
    enable = lib.mkEnableOption "the read-only UniFi Network API adapter";
    pinnedCertificate = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Public controller leaf certificate matching the independently confirmed SHA256 pin; trusted only by this adapter.";
    };
    caFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to a CA certificate bundle used to verify the UniFi controller TLS certificate.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.UNIFI_API_KEY.sopsFile = ../../../../secrets/shared.yaml;

    home.packages = [wrapper];

    programs.mcp.servers.unifi-readonly = {
      command = lib.getExe wrapper;
      args = ["mcp"];
    };

    home.file."${config.programs.claude-code.configDir}/skills/unifi-readonly/SKILL.md".source = ./SKILL.md;
  };
}
