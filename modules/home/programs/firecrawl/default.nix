{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  version = (lib.importJSON "${inputs.firecrawl-cli}/package.json").version;
  skills = [
    "firecrawl"
    "firecrawl-scrape"
    "firecrawl-search"
    "firecrawl-crawl"
    "firecrawl-map"
    "firecrawl-interact"
    "firecrawl-agent"
    "firecrawl-monitor"
    "firecrawl-parse"
    "firecrawl-download"
    "firecrawl-alexandria"
    "firecrawl-research-index"
    "firecrawl-developer-index"
  ];
  skillSources = lib.genAttrs skills (name: "${inputs.firecrawl-cli}/skills/${name}");
  url = "https://mcp.firecrawl.dev/v2/mcp";
  secretPath = lib.escapeShellArg config.sops.secrets.FIRECRAWL_API_KEY.path;
  # Claude Code runs this on every connect and sends the JSON it prints as
  # headers. --rawfile keeps the key out of argv.
  headersHelper = pkgs.writeShellScript "firecrawl-mcp-headers" ''
    exec ${lib.getExe pkgs.jq} -n --rawfile key ${secretPath} \
      '{Authorization: ("Bearer " + ($key | rtrimstr("\n")))}'
  '';
  wrapper = pkgs.writeShellScriptBin "firecrawl" ''
    export PATH=${lib.makeBinPath [pkgs.nodejs_24]}:$PATH
    if [ -z "''${FIRECRAWL_API_KEY:-}" ] && [ -r ${secretPath} ]; then
      export FIRECRAWL_API_KEY="$(<${secretPath})"
    fi
    exec npx -y firecrawl-cli@${version} "$@"
  '';
  claudeSkills =
    lib.mapAttrs'
    (name: source: lib.nameValuePair "${config.programs.claude-code.configDir}/skills/${name}" {inherit source;})
    skillSources;
in {
  config = lib.mkMerge [
    {
      home.packages = [wrapper];

      # Codex has no headers helper, so it reads the key from the shell
      # environment (../codex/mcp.nix turns this into bearer_token_env_var).
      programs.mcp.servers.firecrawl = {
        inherit url;
        headers.Authorization = "Bearer \${FIRECRAWL_API_KEY}";
      };
    }
    (lib.mkIf config.programs.claude-code.enable {
      home.file = claudeSkills;
      # Replaces the entry above for Claude Code, so agents started by a
      # launcher whose environment predates the key still authenticate.
      programs.claude-code.mcpServers.firecrawl = {
        inherit url;
        headersHelper = "${headersHelper}";
      };
    })
    (lib.mkIf config.programs.codex.enable {
      programs.codex.skills = skillSources;
    })
  ];
}
