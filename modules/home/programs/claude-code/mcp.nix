{
  config,
  lib,
  pkgs,
  ...
}: {
  # Secrets live as individual sops entries decrypted to
  # /run/user/$UID/secrets/<NAME>; their values never enter /nix/store.
  # These secrets are shared across hosts, so they're sourced from
  # secrets/shared.yaml rather than the per-host sops file.
  sops.secrets = let
    sharedFile = ../../../../secrets/shared.yaml;
  in {
    CLAUDE_SANITY_MCP_BEARER.sopsFile = sharedFile;
    N8N_ACCESS_TOKEN.sopsFile = sharedFile;
    NOCODB_API_KEY.sopsFile = sharedFile;
    PAPERLESS_API_KEY.sopsFile = sharedFile;
  };

  # Expose the Claude MCP secrets as shell env vars. The MCP server
  # declarations below reference them as `${VAR}` placeholders — Claude
  # Code performs the env-substitution when it launches each server, so
  # the JSON files on disk only ever contain the placeholder text.
  programs.fish.shellInitLast = lib.mkAfter ''
    for pair in \
        CLAUDE_SANITY_MCP_BEARER:${config.sops.secrets.CLAUDE_SANITY_MCP_BEARER.path} \
        N8N_ACCESS_TOKEN:${config.sops.secrets.N8N_ACCESS_TOKEN.path} \
        NOCODB_API_KEY:${config.sops.secrets.NOCODB_API_KEY.path} \
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
        CLAUDE_SANITY_MCP_BEARER:${config.sops.secrets.CLAUDE_SANITY_MCP_BEARER.path} \
        N8N_ACCESS_TOKEN:${config.sops.secrets.N8N_ACCESS_TOKEN.path} \
        NOCODB_API_KEY:${config.sops.secrets.NOCODB_API_KEY.path} \
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
      # Native HTTP rather than an `npx mcp-remote` bridge: a bridge gets
      # the expanded key in its argv, where `ps` shows it to every user.
      nocodb-the-connection = {
        url = "https://nocodb.theswisscheese.com/mcp/nc5tvdxynrmu24vo";
        headers.x-api-key = "\${NOCODB_API_KEY}";
      };

      Sanity = {
        url = "https://mcp.sanity.io";
        headers.Authorization = "Bearer \${CLAUDE_SANITY_MCP_BEARER}";
      };

      n8n-mcp = {
        url = "https://n8n.theswisscheese.com/mcp-server/http";
        headers.Authorization = "Bearer \${N8N_ACCESS_TOKEN}";
      };

      # One remote Figma server per Figma account. Claude Code keeps the
      # OAuth token per server name, so each one is signed in separately
      # through /mcp. The acct query parameter only tells the URLs apart.
      figma-almost-always.url = "https://mcp.figma.com/mcp?acct=almost-always";
      figma-personal.url = "https://mcp.figma.com/mcp?acct=personal";

      # One remote Linear server per Linear workspace, signed in the same
      # way as Figma above.
      linear-swiss-cheese.url = "https://mcp.linear.app/mcp?acct=swiss-cheese";
      linear-almost-always.url = "https://mcp.linear.app/mcp?acct=almost-always";

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
