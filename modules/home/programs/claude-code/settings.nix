{inputs, ...}: {
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
    agentsDir = ./agents;
    rulesDir = ./rules;
    context = ./CLAUDE.md;
    skills = ./skills;
    hooks = {
      "block-rm-rf.sh" = builtins.readFile ./hooks/block-rm-rf.sh;
      "enforce-bun.sh" = builtins.readFile ./hooks/enforce-bun.sh;
      "context-mode-cache-heal.mjs" = builtins.readFile ./hooks/context-mode-cache-heal.mjs;
    };
    plugins = [
      inputs.context-mode
      inputs.caveman
    ];
    settings = {
      effortLevel = "xhigh";
      skillListingBudgetFraction = 0.02;
      skillListingMaxDescChars = 2048;
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
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "bash ~/.claude/hooks/enforce-bun.sh";
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
