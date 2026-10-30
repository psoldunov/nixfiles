# Resolves the `${VAR}` placeholders in programs.mcp.servers at launch.
#
# A client fills a placeholder from its own environment, and a long-running
# launcher (concierge-daemon, which starts Claude Code and Codex agents) hands
# its agents the environment it captured at its own start. A secret added
# after that never reaches them. So every placeholder is read when the server
# starts or connects, through programs.claude-code.mcpSecretReaders:
#
#   stdio server   wrap it in mcpLaunchEnv (below); Claude Code, Codex and pi
#                  all run the wrapper.
#   HTTP server    nothing to do: Claude Code's copy moves the placeholder
#                  headers into a headersHelper. Codex and pi cannot run one,
#                  so they still read the variable from their environment.
#
# Evaluation fails if a placeholder sits anywhere but an HTTP header.
{
  config,
  lib,
  pkgs,
  ...
}: let
  placeholder = "\\$\\{([A-Za-z_][A-Za-z0-9_]*)(:-)?}";
  pieces = builtins.split placeholder;
  # Variables a value references.
  varsIn = value:
    if builtins.isString value
    then map lib.head (lib.filter lib.isList (pieces value))
    else [];
  hasPlaceholder = value: varsIn value != [];

  readerOf = var:
    config.programs.claude-code.mcpSecretReaders.${var}
    or (throw "MCP secret ${var} has no reader: add it to sops or set programs.claude-code.mcpSecretReaders.${var}");
  # Bash that reads each variable into the environment, or exits on failure.
  readVars = vars:
    lib.concatMapStrings (var: ''
      ${var}=$(${readerOf var}) || exit 1
      export ${var}
    '') (lib.unique vars);

  mcpLaunchEnv = name: server: let
    secret = lib.filterAttrs (_: hasPlaceholder) (server.env or {});
    wholeVar = value: let
      m = builtins.match placeholder value;
    in
      if m == null
      then throw "mcpLaunchEnv ${name}: an env value must be a single \${VAR}, got ${value}"
      else lib.head m;
    wrapper = pkgs.writeShellScript "mcp-${name}" ''
      ${lib.concatStrings (lib.mapAttrsToList (env: value: ''
          ${env}=$(${readerOf (wholeVar value)}) || exit 1
          export ${env}
        '')
        secret)}
      exec ${lib.escapeShellArgs ([server.command] ++ server.args or [])} "$@"
    '';
  in
    server
    // {
      command = "${wrapper}";
      args = [];
      env = removeAttrs (server.env or {}) (lib.attrNames secret);
    };

  # "Bearer ${X}" -> ("Bearer " + $ENV.X), the jq expression that builds it.
  jqValue = value: let
    parts =
      map (p:
        if lib.isList p
        then "$ENV.${lib.head p}"
        else builtins.toJSON p)
      (lib.filter (p: p != "") (pieces value));
  in "(${lib.concatStringsSep " + " parts})";

  # Claude Code's copy of an HTTP server. The values travel to jq through
  # its environment, so no secret shows up in an argv.
  withHeadersHelper = name: server: let
    secret = lib.filterAttrs (_: hasPlaceholder) server.headers;
    object = lib.concatStringsSep ", " (lib.mapAttrsToList (header: value: "${builtins.toJSON header}: ${jqValue value}") secret);
    helper = pkgs.writeShellScript "mcp-${name}-headers" ''
      ${readVars (lib.concatMap varsIn (lib.attrValues secret))}
      exec ${lib.getExe pkgs.jq} -n ${lib.escapeShellArg "{${object}}"}
    '';
  in
    lib.hm.mcp.transformMcpServer {
      server =
        server
        // {
          headers = removeAttrs server.headers (lib.attrNames secret);
          headersHelper = "${helper}";
        };
      extraTransforms = [lib.hm.mcp.addType];
    };

  servers = config.programs.mcp.servers;
  stranded = lib.attrNames (lib.filterAttrs (_: server: lib.hasInfix "\${" (builtins.toJSON (removeAttrs server ["headers"]))) servers);
in {
  options.programs.claude-code.mcpSecretReaders = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {};
    description = ''
      A shell command printing the value of each `''${VAR}` that a server in
      programs.mcp.servers uses. Every sops secret reads its decrypted file
      unless set here.
    '';
  };

  config = {
    _module.args.mcpLaunchEnv = mcpLaunchEnv;

    programs.claude-code.mcpSecretReaders =
      lib.mapAttrs (_: secret: lib.mkDefault "${lib.getExe' pkgs.coreutils "cat"} ${lib.escapeShellArg secret.path}")
      config.sops.secrets;

    programs.claude-code.mcpServers =
      lib.mapAttrs withHeadersHelper
      (lib.filterAttrs (_: server: lib.any hasPlaceholder (lib.attrValues server.headers)) servers);

    assertions = [
      {
        assertion = stranded == [];
        message = "MCP servers ${lib.concatStringsSep ", " stranded} hold a \${VAR} outside their headers; wrap a stdio server in mcpLaunchEnv (modules/home/programs/claude-code/mcp-secrets.nix).";
      }
    ];
  };
}
