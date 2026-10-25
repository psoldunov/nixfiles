# Codex's MCP servers: every entry in programs.mcp.servers (../claude-code/mcp.nix,
# ../../workstation/, ../unifi/), plus two that Claude Code gets from claude.ai.
#
# Those entries carry Claude Code's `${VAR}` placeholders, which Codex would
# send as text. Each one is pointed at the variable instead:
#   Authorization = "Bearer ${X}"  ->  bearer_token_env_var = "X"
#   <header> = "${X}"              ->  env_http_headers.<header> = "X"
#   env.X = "${X}"                 ->  env_vars = ["X"] (passed on from Codex's env)
# Evaluation fails if a placeholder is left over.
{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "([A-Za-z_][A-Za-z0-9_]*)";
  # The variable named by "${VAR}" or "${VAR:-}", else null.
  refOf = value: let
    m =
      if builtins.isString value
      then builtins.match "\\$\\{${name}(:-)?}" value
      else null;
  in
    if m == null
    then null
    else lib.head m;
  isRef = value: refOf value != null;
  bearerOf = value: let
    m = builtins.match "Bearer \\$\\{${name}(:-)?}" value;
  in
    if m == null
    then null
    else lib.head m;

  rewritePlaceholders = serverName: server: let
    headers = server.headers or {};
    bearer =
      if headers ? Authorization
      then bearerOf headers.Authorization
      else null;
    otherHeaders = removeAttrs headers (lib.optional (bearer != null) "Authorization");
    envRefs = lib.filterAttrs (_: isRef) (server.env or {});
  in
    lib.throwIf (lib.any (var: refOf envRefs.${var} != var) (lib.attrNames envRefs))
    "codex: MCP server ${serverName} sets an env var from a differently named one, which env_vars cannot express"
    (server
      // {
        bearer_token_env_var = bearer;
        env_http_headers = lib.mapAttrs (_: refOf) (lib.filterAttrs (_: isRef) otherHeaders);
        http_headers = lib.filterAttrs (_: value: !isRef value) otherHeaders;
        env = removeAttrs (server.env or {}) (lib.attrNames envRefs);
        env_vars = lib.attrNames envRefs;
      }
      # Codex's 10 s default is too short for a cold npx or bunx download.
      // lib.optionalAttrs ((server.command or null) != null) {startup_timeout_sec = 60;});

  # transformMcpServer drops the null and empty values left above.
  servers =
    lib.mapAttrs (serverName: server:
      lib.hm.mcp.transformMcpServer {
        inherit server;
        exclude = ["headers" "type"];
        extraTransforms = [
          (rewritePlaceholders serverName)
          (lib.hm.mcp.wrapEnvFilesCommand {
            inherit pkgs;
            name = serverName;
          })
        ];
      })
    config.programs.mcp.servers
    // {
      context7.url = "https://mcp.context7.com/mcp";
      # Sign in with `codex mcp login vercel`.
      vercel.url = "https://mcp.vercel.com";
    };
in {
  config = lib.mkIf config.programs.codex.enable {
    programs.codex.settings.mcp_servers =
      lib.throwIf (lib.hasInfix "\${" (builtins.toJSON servers))
      "codex: an MCP server still holds a \${VAR} placeholder, which Codex would send as text"
      servers;
  };
}
