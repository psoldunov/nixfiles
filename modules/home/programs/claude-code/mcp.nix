{
  config,
  lib,
  pkgs,
  ...
}: {
  # Secrets live as individual sops entries decrypted to
  # /run/user/$UID/secrets/<NAME>; their values never enter /nix/store.
  sops.secrets = {
    CLAUDE_GEMINI_API_KEY = {};
    CLAUDE_MAGIC_21ST_API_KEY = {};
    CLAUDE_NOCODB_MCP_URL = {};
    CLAUDE_NOCODB_MCP_TOKEN = {};
    CLAUDE_SANITY_MCP_BEARER = {};
  };

  # Expose the Claude MCP secrets as shell env vars. The MCP server
  # declarations below reference them as `${VAR}` placeholders — Claude
  # Code performs the env-substitution when it launches each server, so
  # the JSON files on disk only ever contain the placeholder text.
  programs.fish.shellInitLast = lib.mkAfter ''
    set -gx CLAUDE_GEMINI_API_KEY (command cat ${config.sops.secrets.CLAUDE_GEMINI_API_KEY.path})
    set -gx CLAUDE_MAGIC_21ST_API_KEY (command cat ${config.sops.secrets.CLAUDE_MAGIC_21ST_API_KEY.path})
    set -gx CLAUDE_NOCODB_MCP_URL (command cat ${config.sops.secrets.CLAUDE_NOCODB_MCP_URL.path})
    set -gx CLAUDE_NOCODB_MCP_TOKEN (command cat ${config.sops.secrets.CLAUDE_NOCODB_MCP_TOKEN.path})
    set -gx CLAUDE_SANITY_MCP_BEARER (command cat ${config.sops.secrets.CLAUDE_SANITY_MCP_BEARER.path})
  '';
  programs.bash.bashrcExtra = lib.mkAfter ''
    export CLAUDE_GEMINI_API_KEY="$(<${config.sops.secrets.CLAUDE_GEMINI_API_KEY.path})"
    export CLAUDE_MAGIC_21ST_API_KEY="$(<${config.sops.secrets.CLAUDE_MAGIC_21ST_API_KEY.path})"
    export CLAUDE_NOCODB_MCP_URL="$(<${config.sops.secrets.CLAUDE_NOCODB_MCP_URL.path})"
    export CLAUDE_NOCODB_MCP_TOKEN="$(<${config.sops.secrets.CLAUDE_NOCODB_MCP_TOKEN.path})"
    export CLAUDE_SANITY_MCP_BEARER="$(<${config.sops.secrets.CLAUDE_SANITY_MCP_BEARER.path})"
  '';

  programs.mcp = {
    enable = true;
    servers = {
      nanobanana = {
        command = "${pkgs.uv}/bin/uvx";
        args = ["nanobanana-mcp-server@latest"];
        env.GEMINI_API_KEY = "\${CLAUDE_GEMINI_API_KEY}";
      };

      "@21st-dev/magic" = {
        command = "${pkgs.nodejs_24}/bin/npx";
        args = [
          "-y"
          "@21st-dev/magic@latest"
          "API_KEY=\${CLAUDE_MAGIC_21ST_API_KEY}"
        ];
      };

      nocodb = {
        command = "${pkgs.nodejs_24}/bin/npx";
        args = [
          "mcp-remote"
          "\${CLAUDE_NOCODB_MCP_URL}"
          "--header"
          "xc-mcp-token: \${CLAUDE_NOCODB_MCP_TOKEN}"
        ];
      };

      Sanity = {
        url = "https://mcp.sanity.io";
        headers.Authorization = "Bearer \${CLAUDE_SANITY_MCP_BEARER}";
      };

      obsidian-personal = {
        command = "${pkgs.nodejs_24}/bin/npx";
        args = [
          "@bitbonsai/mcpvault@latest"
          "${config.home.homeDirectory}/Documents/Obsidian/Personal"
        ];
      };

      obsidian-boundary = {
        command = "${pkgs.nodejs_24}/bin/npx";
        args = [
          "@bitbonsai/mcpvault@latest"
          "${config.home.homeDirectory}/Documents/Obsidian/Boundary"
        ];
      };
    };
  };
}
