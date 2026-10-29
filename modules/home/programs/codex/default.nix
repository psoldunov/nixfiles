# Codex CLI (~/.codex). Hosts opt in with `programs.codex.enable` (the
# workstations, in ../../workstation/default.nix); home-manager's own module
# does the writing. This one gives Codex what Claude Code has: MCP servers
# (./mcp.nix), rules (./instructions.nix), skills (./skills.nix) and agents
# (./agents.nix). See ./CLAUDE.md.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  # The rm -rf guard Claude Code runs, with its jq and grep pinned.
  blockRmRf = pkgs.writeShellScript "codex-block-rm-rf" ''
    export PATH=${lib.makeBinPath [pkgs.jq pkgs.gnugrep]}:$PATH
    exec ${lib.getExe pkgs.bash} ${../claude-code/hooks/block-rm-rf.sh}
  '';
in {
  imports = [
    ./agents.nix
    ./instructions.nix
    ./mcp.nix
    ./skills.nix
  ];

  config = lib.mkIf config.programs.codex.enable {
    programs.codex = {
      # Installed outside home-manager: system-wide on Whopper, the Homebrew
      # cask on the Macs.
      package = lib.mkDefault null;
      # Codex writes config.toml itself (project trust, /model, hook trust), so
      # it stays a real file; activation merges the declared keys into it.
      mutableSettings = true;
      # Both ship Codex plugins: context-mode brings its MCP server, routing
      # hooks and skills, ponytail its always-on hooks and skills.
      plugins = [inputs.context-mode inputs.ponytail];
      # A folder's CLAUDE.md loads when the folder has no AGENTS.md.
      settings.project_doc_fallback_filenames = ["CLAUDE.md"];
      # Web search goes through the searxng MCP server (BigTasty's SearXNG),
      # as in Claude Code; this unregisters Codex's built-in tool.
      settings.web_search = "disabled";
      hooks.PreToolUse = [
        {
          matcher = "^Bash$";
          hooks = [
            {
              type = "command";
              command = "${blockRmRf}";
              timeout = 30;
            }
          ];
        }
      ];
    };
  };
}
