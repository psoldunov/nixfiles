{inputs, ...}: {
  programs.claude-code = {
    enable = true;
    agentsDir = ./agents;
    context = ./CLAUDE.md;
    skills = ./skills;
    hooks = {
      "block-rm-rf.sh" = builtins.readFile ./hooks/block-rm-rf.sh;
      "enforce-bun.sh" = builtins.readFile ./hooks/enforce-bun.sh;
      "context-mode-cache-heal.mjs" = builtins.readFile ./hooks/context-mode-cache-heal.mjs;
    };
    plugins = [
      inputs.context-mode
    ];
    settings = {
      effortLevel = "xhigh";
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
      enabledPlugins = {
        "skill-creator@claude-plugins-official" = true;
        "superpowers@claude-plugins-official" = true;
        "figma@claude-plugins-official" = true;
        "vercel@claude-plugins-official" = true;
      };
    };

    # MCP servers — written into the HM-managed plugin's .mcp.json.
    # mcpServers = {
    #   github = {
    #     type = "http";
    #     url  = "https://api.githubcopilot.com/mcp/";
    #   };
    # };

    # Drop slash-command .md files into ./commands and enable this.
    # commandsDir = ./commands;
  };
}
