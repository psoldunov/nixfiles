# clokkr-gate: root agents log the time they spend on client repos to Clokkr.
# Claude Code and Codex run clokkr-gate.mjs as UserPromptSubmit and Stop hooks;
# pi loads index.ts from this folder. It is on wherever a host declares the
# Clokkr MCP server (hosts/*/home/programs/clokkr.nix), whose command is also
# the CLI the hook reads Clokkr with. See ./CLAUDE.md.
{
  config,
  lib,
  ...
}: let
  clokkr = config.programs.mcp.servers.clokkr or null;
  # A stable path, not a store path: settings.json unions hook arrays across
  # rebuilds, and Codex trusts a hook by its command string.
  hook = event: {
    hooks = [
      {
        type = "command";
        command = "node ~/.claude/hooks/clokkr-gate.mjs ${event}";
        timeout = 30;
      }
    ];
  };
  hooks = {
    UserPromptSubmit = [(hook "prompt")];
    Stop = [(hook "stop")];
  };
in {
  config = lib.mkIf (clokkr != null) {
    xdg.configFile."clokkr-gate/config.json".text = builtins.toJSON {
      cli = clokkr.command;
      # A repo in one of these orgs is client work. One that no Clokkr task
      # names yet has the agent set its client up in Clokkr.
      clientOrgs = ["boundary-digital"];
      # Almost Always's own repos: in a client org, not client work.
      internalRepos = [
        "boundary-digital/almost-always"
        "boundary-digital/almost-always-vps"
      ];
    };
    programs.claude-code.hooks."clokkr-gate.mjs" = builtins.readFile ./clokkr-gate.mjs;
    programs.claude-code.settings.hooks = hooks;
    # The calls the hook asks for, so logging a turn never waits on a prompt.
    programs.claude-code.settings.permissions.allow =
      map (tool: "mcp__plugin_hm_clokkr__${tool}") ["list_tasks" "add_session" "create_folder" "create_task" "update_node"];
    programs.codex.hooks = hooks;
    # pi loads index.ts, which imports ./clokkr-gate.mjs beside it.
    home.file."${config.programs.pi-coding-agent.configDir}/extensions/clokkr-gate".source = ./.;
  };
}
