{
  config,
  lib,
  pkgs,
  hostConfig,
  ...
}: {
  # Secrets live as individual sops entries decrypted to
  # /run/user/$UID/secrets/<NAME>; their values never enter /nix/store.
  # These secrets are shared across hosts, so they're sourced from
  # secrets/shared.yaml rather than the per-host sops file.
  sops.secrets = let
    sharedFile = ../../../../secrets/shared.yaml;
  in {
    CLAUDE_GEMINI_API_KEY.sopsFile = sharedFile;
    CLAUDE_MAGIC_21ST_API_KEY.sopsFile = sharedFile;
    CLAUDE_NOCODB_MCP_URL.sopsFile = sharedFile;
    CLAUDE_NOCODB_MCP_TOKEN.sopsFile = sharedFile;
    CLAUDE_SANITY_MCP_BEARER.sopsFile = sharedFile;
    PAPERLESS_API_KEY.sopsFile = sharedFile;
  };

  # Expose the Claude MCP secrets as shell env vars. The MCP server
  # declarations below reference them as `${VAR}` placeholders — Claude
  # Code performs the env-substitution when it launches each server, so
  # the JSON files on disk only ever contain the placeholder text.
  programs.fish.shellInitLast = lib.mkAfter ''
    for pair in \
        CLAUDE_GEMINI_API_KEY:${config.sops.secrets.CLAUDE_GEMINI_API_KEY.path} \
        CLAUDE_MAGIC_21ST_API_KEY:${config.sops.secrets.CLAUDE_MAGIC_21ST_API_KEY.path} \
        CLAUDE_NOCODB_MCP_URL:${config.sops.secrets.CLAUDE_NOCODB_MCP_URL.path} \
        CLAUDE_NOCODB_MCP_TOKEN:${config.sops.secrets.CLAUDE_NOCODB_MCP_TOKEN.path} \
        CLAUDE_SANITY_MCP_BEARER:${config.sops.secrets.CLAUDE_SANITY_MCP_BEARER.path} \
        PAPERLESS_API_KEY:${config.sops.secrets.PAPERLESS_API_KEY.path}
      set name (string split -m1 ':' $pair)[1]
      set path (string split -m1 ':' $pair)[2]
      if test -r $path
        set -gx $name (command cat $path)
      end
    end
  '';
  programs.bash.bashrcExtra = lib.mkAfter ''
    for pair in \
        CLAUDE_GEMINI_API_KEY:${config.sops.secrets.CLAUDE_GEMINI_API_KEY.path} \
        CLAUDE_MAGIC_21ST_API_KEY:${config.sops.secrets.CLAUDE_MAGIC_21ST_API_KEY.path} \
        CLAUDE_NOCODB_MCP_URL:${config.sops.secrets.CLAUDE_NOCODB_MCP_URL.path} \
        CLAUDE_NOCODB_MCP_TOKEN:${config.sops.secrets.CLAUDE_NOCODB_MCP_TOKEN.path} \
        CLAUDE_SANITY_MCP_BEARER:${config.sops.secrets.CLAUDE_SANITY_MCP_BEARER.path} \
        PAPERLESS_API_KEY:${config.sops.secrets.PAPERLESS_API_KEY.path}; do
      name="''${pair%%:*}"
      path="''${pair#*:}"
      if [ -r "$path" ]; then
        export "$name"="$(<"$path")"
      fi
    done
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
          "${hostConfig.obsidianBase}/Personal"
        ];
      };

      obsidian-boundary = {
        command = "${pkgs.nodejs_24}/bin/npx";
        args = [
          "@bitbonsai/mcpvault@latest"
          "${hostConfig.obsidianBase}/Boundary"
        ];
      };

      Paperless = {
        command = "${pkgs.bun}/bin/bunx";
        args = [
          "-y"
          "@psoldunov/paperless-mcp@0.4.2"
        ];
        env = {
          PAPERLESS_URL = "http://10.24.24.2:28981";
          PAPERLESS_API_KEY = "\${PAPERLESS_API_KEY}";
          PAPERLESS_PUBLIC_URL = "https://paperless.theswisscheese.com";
        };
      };
    };
  };
}
