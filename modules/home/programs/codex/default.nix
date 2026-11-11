# Codex CLI (~/.codex). Hosts opt in with `programs.codex.enable` (the
# workstations, in ../../workstation/default.nix); home-manager's own module
# does the writing. This one gives Codex what Claude Code has: MCP servers
# (./mcp.nix), rules (./instructions.nix), skills (./skills.nix), agents
# (./agents.nix), plugins (./plugins.nix) and hooks (below). See ./CLAUDE.md.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  # Claude Code's hooks and mods, each run with its tools pinned. Each one is
  # copied to the store on its own: Codex asks to trust a hook again whenever
  # its command (a store path) changes, so an unrelated edit must not move it.
  bash = name: script: deps:
    pkgs.writeShellScript "codex-${name}" ''
      export PATH=${lib.makeBinPath deps}:$PATH
      exec ${lib.getExe pkgs.bash} ${script}
    '';
  # Node 24 runs the mods' erasable TypeScript as it is.
  node = name: mod:
    pkgs.writeShellScript "codex-${name}" ''
      exec ${lib.getExe pkgs.nodejs} --no-warnings ${mod}/codex.ts
    '';

  hook = command: timeout: {
    type = "command";
    command = "${command}";
    inherit timeout;
  };

  blockRmRf = hook (bash "block-rm-rf" ../claude-code/hooks/block-rm-rf.sh [pkgs.jq pkgs.gnugrep]) 30;
  # i-have-adhd's per-prompt reminder; silent unless the always-on flag exists.
  adhdReminder = hook (bash "adhd-final-response" ../claude-code/hooks/adhd-final-response.sh [pkgs.coreutils]) 10;
  nixOwnedPaths = hook (node "nix-owned-paths" ../claude-code/mods/nix-owned-paths) 10;
  humanizerGate = hook (node "humanizer-gate" ../claude-code/mods/humanizer-gate) 10;
  # Impeccable's design checks, as its repo's .codex/hooks.json runs them. The
  # launcher fetches its engine into ~/.impeccable/ on first use.
  impeccable = hook "${inputs.impeccable}/.agents/skills/impeccable/scripts/impeccable hook";
in {
  imports = [
    ./agents.nix
    ./instructions.nix
    ./mcp.nix
    ./plugins.nix
    ./skills.nix
  ];

  config = lib.mkIf config.programs.codex.enable {
    programs.codex = {
      # Installed outside home-manager: system-wide on Whopper and BigTasty,
      # the Homebrew cask on the Macs.
      package = lib.mkDefault null;
      # Codex writes config.toml itself (project trust, /model, hook trust), so
      # it stays a real file; activation merges the declared keys into it.
      mutableSettings = true;
      # A folder's CLAUDE.md loads when the folder has no AGENTS.md.
      settings.project_doc_fallback_filenames = ["CLAUDE.md"];
      # Web search goes through the searxng MCP server (BigTasty's SearXNG),
      # as in Claude Code; this unregisters Codex's built-in tool.
      settings.web_search = "disabled";
      # Codex's matchers are regexes on the hook tool name: `Bash` for shell
      # commands, `apply_patch` for file edits, `mcp__<server>__<tool>` for MCP.
      hooks = {
        PreToolUse = [
          {
            matcher = "^Bash$";
            hooks = [blockRmRf];
          }
          {
            matcher = "^apply_patch$";
            hooks = [nixOwnedPaths];
          }
          {
            matcher = "^(Bash|apply_patch|mcp__.*)$";
            hooks = [humanizerGate];
          }
        ];
        PostToolUse = [
          {
            matcher = "^apply_patch$";
            hooks = [(impeccable 5)];
          }
        ];
        Stop = [{hooks = [(impeccable 30)];}];
        UserPromptSubmit = [{hooks = [adhdReminder];}];
      };
    };
  };
}
