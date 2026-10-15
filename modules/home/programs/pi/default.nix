# Pi coding agent (~/.pi/agent). Hosts opt in with
# `programs.pi-coding-agent.enable`; home-manager's own module installs the
# package, and this one adds the claude-bridge extension, which gives pi the
# rules, CLAUDE.md files, skills and agents Claude Code already has, and the
# humanizer-gate extension, the pi half of Claude Code's mod of that name (see
# ./CLAUDE.md).
#
# programs.pi-coding-agent.settings stays unset on purpose: home-manager would
# turn settings.json into a read-only store symlink, and pi writes to it
# (`/model`, `/settings`, `pi install`, the changelog marker).
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.pi-coding-agent;
  piCommand =
    if cfg.package == null
    then "${pkgs.coreutils}/bin/false"
    else "${cfg.package}/bin/pi";
  piPackages = [
    "npm:pi-mcp-adapter"
    "npm:pi-lens"
    "npm:pi-web-access"
    "npm:@sting8k/pi-vcc"
  ];

  # Read by extensions/claude-bridge/config.ts. Every key is optional there;
  # these values match its defaults and are spelled out to be tuned here.
  claudeBridge = {
    claudeDir = config.programs.claude-code.configDir;
    # The project's .claude/ (rules, skills, agents, CLAUDE.md), once pi trusts the project.
    projectClaude = true;
    # Results of these tools trigger path-scoped rules and nested CLAUDE.md.
    lazyTools = ["read" "edit" "write"];
    memory = {
      enabled = true;
      nested = true;
    };
    rules.enabled = true;
    skills = {
      enabled = true;
      # Skill ids are `<source>:<dir>`. context-mode's skills drive its ctx_*
      # MCP tools, which pi does not have; synced/ holds claude.ai's skills.
      # reverse-engineer-anything drives the rea MCP server the same way.
      exclude = ["context-mode:*" "synced:*" "user:reverse-engineer-anything"];
      # `/name` and `/plugin:name` next to pi's `/skill:name`.
      aliases = true;
    };
    agents = {
      enabled = true;
      exclude = [];
      # Claude `model:` value -> pi "provider/id", e.g. opus = "anthropic/claude-opus-5-5".
      # Unmapped values run on the session's model.
      modelMap = {};
      builtins = true;
      descriptionMaxChars = 400;
      outputMaxBytes = 20480;
      # Only the top-level session gets the Agent tool.
      maxDepth = 1;
    };
  };
in {
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.package != null;
        message = "Pi package activation requires programs.pi-coding-agent.package to be non-null.";
      }
    ];

    # npm is needed both during activation and by Pi's package commands later.
    programs.pi-coding-agent.extraPackages = [pkgs.nodejs];

    home.activation.piPackages = lib.hm.dag.entryAfter ["linkGeneration"] ''
      if [[ -n "''${DRY_RUN_CMD:-}" ]]; then
        echo "Would ensure Pi packages: ${lib.concatStringsSep " " piPackages}"
      else
        (
          export PI_CODING_AGENT_DIR=${lib.escapeShellArg cfg.configDir}
          export PATH=${lib.makeBinPath ([pkgs.nodejs] ++ cfg.extraPackages)}:"$PATH"
          # Do not let the activation working directory supply project settings.
          cd ${lib.escapeShellArg config.home.homeDirectory}
          settings="$PI_CODING_AGENT_DIR/settings.json"
          if [[ -e "$settings" ]]; then
            ${lib.getExe pkgs.jq} -e 'type == "object" and ((.packages // []) | type == "array")' "$settings" >/dev/null
          fi
          for source in ${lib.escapeShellArgs piPackages}; do
            installedSource=""
            if [[ -e "$settings" ]]; then
              # Keep user version pins and object entries with resource filters.
              installedSource=$(${lib.getExe pkgs.jq} -r --arg source "$source" '
                first((.packages // [])[] | if type == "string" then . else .source end
                  | select(. == $source or startswith($source + "@"))) // empty
              ' "$settings")
            fi
            name="''${source#npm:}"
            if [[ -z "$installedSource" || ! -f "$PI_CODING_AGENT_DIR/npm/node_modules/$name/package.json" ]]; then
              ${piCommand} install "''${installedSource:-$source}" --no-approve
            fi
          done
        )
      fi
    '';

    home.file = {
      "${cfg.configDir}/extensions/claude-bridge".source = ./extensions/claude-bridge;
      # One folder serves both agents: Claude Code loads hooks/register.ts, pi
      # loads index.ts. Linked whole so index.ts can import ./hooks/policy.ts.
      "${cfg.configDir}/extensions/humanizer-gate".source = ../claude-code/mods/humanizer-gate;
      "${cfg.configDir}/claude-bridge.json".text = builtins.toJSON claudeBridge;
    };
  };
}
