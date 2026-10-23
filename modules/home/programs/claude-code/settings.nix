{
  config,
  inputs,
  lib,
  pkgs,
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
    i-have-adhd = inputs.i-have-adhd;
    # Also pi's extension of the same name (../pi/default.nix).
    ponytail = inputs.ponytail;
    # Local mods: function-hook plugins kept in this repo.
    nix-owned-paths = ./mods/nix-owned-paths;
    # Also pi's extension of the same name (../pi/default.nix).
    humanizer-gate = ./mods/humanizer-gate;
  };
in {
  home.file =
    {
      # Taste v2 has a marketplace manifest, not a plugin manifest; link the skill itself.
      "${configDir}/skills/design-taste-frontend".source = "${inputs.taste-skill}/skills/taste-skill";
      # Codex's standard user skill directory; Pi also discovers this location.
      ".agents/skills/design-taste-frontend".source = "${inputs.taste-skill}/skills/taste-skill";
      # Cloudflare's security-audit skill: a bare skill repo, linked for both locations.
      "${configDir}/skills/security-audit".source = "${inputs.security-audit-skill}/skills/security-audit";
      ".agents/skills/security-audit".source = "${inputs.security-audit-skill}/skills/security-audit";
      # Microsoft's official playwright-cli skill, linked next to ./skills.
      "${configDir}/skills/playwright-cli".source = "${inputs.playwright-cli}/skills/playwright-cli";
      # Matt Pocock's grill-me and grill-with-docs. Both only call the Skill
      # tool, so grilling and domain-modeling come along as their dependencies.
      "${configDir}/skills/grill-me".source = "${inputs.mattpocock-skills}/skills/productivity/grill-me";
      "${configDir}/skills/grilling".source = "${inputs.mattpocock-skills}/skills/productivity/grilling";
      "${configDir}/skills/grill-with-docs".source = "${inputs.mattpocock-skills}/skills/engineering/grill-with-docs";
      "${configDir}/skills/domain-modeling".source = "${inputs.mattpocock-skills}/skills/engineering/domain-modeling";
      # Opts in to i-have-adhd's always-on mode: its SessionStart hook injects
      # the full ruleset, and hooks/adhd-final-response.sh re-asserts it on
      # every prompt. Remove this entry to switch both off.
      "${configDir}/.i-have-adhd-always".text = "";
    }
    // lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) {
      # REA's workflow skill for its rea MCP server (mcp.nix), same release.
      # Linux only, like the server.
      "${configDir}/skills/reverse-engineer-anything".source = "${inputs.rea}/.agents/skills/reverse-engineer-anything";
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
      "adhd-final-response.sh" = builtins.readFile ./hooks/adhd-final-response.sh;
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
        UserPromptSubmit = [
          {
            hooks = [
              {
                type = "command";
                command = "bash ~/.claude/hooks/adhd-final-response.sh";
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
