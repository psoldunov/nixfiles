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
  secretPath = lib.escapeShellArg config.sops.secrets.FIRECRAWL_API_KEY.path;
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

      programs.mcp.servers.firecrawl = {
        url = "https://mcp.firecrawl.dev/v2/mcp";
        headers.Authorization = "Bearer \${FIRECRAWL_API_KEY}";
      };
    }
    (lib.mkIf config.programs.claude-code.enable {
      home.file = claudeSkills;
    })
    (lib.mkIf config.programs.codex.enable {
      programs.codex.skills = skillSources;
    })
  ];
}
