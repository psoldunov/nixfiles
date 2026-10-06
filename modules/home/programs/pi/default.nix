# Pi coding agent (~/.pi/agent). Hosts opt in with
# `programs.pi-coding-agent.enable`; home-manager's own module installs the
# package, and this one adds the claude-bridge extension, which gives pi the
# rules, CLAUDE.md files, skills and agents Claude Code already has (see
# ./CLAUDE.md).
#
# programs.pi-coding-agent.settings stays unset on purpose: home-manager would
# turn settings.json into a read-only store symlink, and pi writes to it
# (`/model`, `/settings`, `pi install`, the changelog marker).
{
  config,
  lib,
  ...
}: let
  cfg = config.programs.pi-coding-agent;

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
      exclude = ["context-mode:*" "synced:*"];
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
    home.file = {
      "${cfg.configDir}/extensions/claude-bridge".source = ./extensions/claude-bridge;
      "${cfg.configDir}/claude-bridge.json".text = builtins.toJSON claudeBridge;
    };
  };
}
