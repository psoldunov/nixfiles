{
  config,
  inputs,
  lib,
  ...
}: let
  inherit (config.programs.claude-code) configDir;

  # Claude Code plugins, each linked whole into skills/<name>. They skip
  # programs.claude-code.plugins: that option rebuilds a plugin as a directory
  # of per-entry symlinks, and Claude Code refuses any manifest path (a
  # ./skills/ folder, a hooks module) whose real location falls outside that
  # directory. A single symlink keeps the source tree as the plugin's real root.
  plugins = {
    context-mode = inputs.context-mode;
    caveman = inputs.caveman;
    # The repo is a marketplace; the plugin itself lives in plugin/.
    impeccable = "${inputs.impeccable}/plugin";
    taste-skill = inputs.taste-skill;
    # Local mods: function-hook plugins kept in this repo.
    nix-owned-paths = ./mods/nix-owned-paths;
  };
in {
  home.file =
    {
      # Microsoft's official playwright-cli skill, linked next to ./skills.
      "${configDir}/skills/playwright-cli".source = "${inputs.playwright-cli}/skills/playwright-cli";
    }
    // lib.mapAttrs' (name: source: lib.nameValuePair "${configDir}/skills/${name}" {inherit source;}) plugins;

  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
    agentsDir = ./agents;
    rulesDir = ./rules;
    # Loads in every project; ./CLAUDE.md loads only when working in this folder.
    context = ./global-CLAUDE.md;
    skills = ./skills;
    hooks = {
      "block-rm-rf.sh" = builtins.readFile ./hooks/block-rm-rf.sh;
      "context-mode-cache-heal.mjs" = builtins.readFile ./hooks/context-mode-cache-heal.mjs;
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
        defaultMode = "auto";
        allow = [
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
                # context-mode rewrites this hook's command to the quoted
                # bare-script form on every MCP boot. Declaring that exact
                # string keeps the array union in mutable-settings.nix from
                # appending a fresh copy on each rebuild.
                command = ''"${configDir}/hooks/context-mode-cache-heal.mjs"'';
              }
            ];
          }
        ];
      };
    };
  };
}
