{
  config,
  inputs,
  ...
}: {
  # Microsoft's official playwright-cli skill, linked next to ./skills.
  home.file."${config.programs.claude-code.configDir}/skills/playwright-cli".source = "${inputs.playwright-cli}/skills/playwright-cli";

  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
    agentsDir = ./agents;
    rulesDir = ./rules;
    context = ./CLAUDE.md;
    skills = ./skills;
    hooks = {
      "block-rm-rf.sh" = builtins.readFile ./hooks/block-rm-rf.sh;
      "context-mode-cache-heal.mjs" = builtins.readFile ./hooks/context-mode-cache-heal.mjs;
    };
    plugins = {
      context-mode = inputs.context-mode;
      caveman = inputs.caveman;
      # The repo is a marketplace; the plugin itself lives in plugin/.
      impeccable = "${inputs.impeccable}/plugin";
      taste-skill = inputs.taste-skill;
      # Local mods: function-hook plugins kept in this repo.
      nix-owned-paths = ./mods/nix-owned-paths;
    };
    settings = {
      effortLevel = "xhigh";
      skillListingBudgetFraction = 0.02;
      skillListingMaxDescChars = 2048;
      # No Co-Authored-By trailer, "Generated with Claude Code" PR footer, or
      # session link in commits and PRs.
      attribution = {
        commit = "";
        pr = "";
        sessionUrl = false;
      };
      statusLine = {
        type = "command";
        command = ''bash "${inputs.caveman}/src/hooks/caveman-statusline.sh"'';
      };
      permissions = {
        allow = [
          "mcp__pencil"
          "mcp__claude_ai_Context7"
          "mcp__plugin_context-mode_context-mode"
        ];
        additionalDirectories = [
          "~/.claude/plans/"
        ];
      };
      hooks = {
        PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "bash ~/.claude/hooks/block-rm-rf.sh";
              }
            ];
          }
        ];
        SessionStart = [
          {
            hooks = [
              {
                type = "command";
                command = "node ~/.claude/hooks/context-mode-cache-heal.mjs";
              }
            ];
          }
        ];
      };
    };
  };
}
