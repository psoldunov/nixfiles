{inputs, ...}: {
  # Declarative Claude Code configuration via home-manager.
  # Options reference:
  # https://home-manager-options.extranix.com/?query=claude-code&release=master
  #
  # Defaults are intentionally conservative: enabling the module alone only
  # installs the `claude-code` binary into `home.packages`. The module writes
  # files under `~/.claude/` only when the corresponding options are non-empty,
  # so existing `~/.claude/settings.json`, agents, hooks, etc. are left alone
  # until they're declared here.
  programs.claude-code = {
    enable = true;
    agentsDir = ./agents;

    # Global memory written to ~/.claude/CLAUDE.md.
    # Drop a CLAUDE.md next to this file and uncomment.
    # context = ./CLAUDE.md;

    # JSON-merged into ~/.claude/settings.json once non-empty.
    # settings = {
    #   theme = "dark";
    #   includeCoAuthoredBy = false;
    #   permissions = {
    #     allow = [ "Bash(git diff:*)" "Edit" ];
    #     ask   = [ "Bash(git push:*)" ];
    #     deny  = [ "WebFetch" "Read(./.env)" ];
    #   };
    # };

    # MCP servers — written into the HM-managed plugin's .mcp.json.
    # mcpServers = {
    #   github = {
    #     type = "http";
    #     url  = "https://api.githubcopilot.com/mcp/";
    #   };
    # };

    # Drop agent .md files into ./agents and enable this.
    # agentsDir = ./agents;

    # Drop slash-command .md files into ./commands and enable this.
    # commandsDir = ./commands;

    # Drop hook scripts into ./hooks and enable this.
    # hooksDir = ./hooks;

    # Skills directory — each subfolder is a skill (with SKILL.md inside).
    # skills = ./skills;
    # Claude Code plugins — declared as paths/packages. The HM module wraps
    # `claude` to load each via `--plugin-dir <path>` at startup.
    plugins = [
      inputs.context-mode
    ];
  };
}
