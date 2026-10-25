# ~/.codex/agents/: Claude Code's agents (../claude-code/agents/) as Codex
# custom agents, plus caveman's cavecrew agents, which its cavecrew skill
# spawns. ./agent-md-to-toml.py converts them; a Claude model tier sets the
# reasoning effort (opus high, sonnet medium, haiku low), and an agent without
# Write or Edit tools gets a read-only sandbox.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  python = pkgs.python3.withPackages (ps: [ps.pyyaml]);
  agents = pkgs.runCommand "codex-agents" {} ''
    mkdir "$out"
    ${lib.getExe python} ${./agent-md-to-toml.py} "$out" \
      ${../claude-code/agents}/*.md ${inputs.caveman}/agents/cavecrew-*.md
  '';
in {
  config = lib.mkIf config.programs.codex.enable {
    # Linked whole: Codex may skip agent files that are themselves symlinks.
    home.file.".codex/agents".source = agents;
  };
}
