# Codex skills, linked into ~/.codex/skills/. That root is Codex's alone:
# ~/.agents/skills would reach pi too, which already gets these through
# claude-bridge. Left out on purpose:
#   - design-taste-frontend, security-audit, brag and brag-slim: settings.nix
#     already links them into ~/.agents/skills, which Codex reads.
#   - context-mode's and ponytail's skills: they come with the plugins
#     (./default.nix).
#   - codex-imagegen: Codex has its own imagegen skill.
# ./instructions.nix adds `tailwind`, ../unifi/ adds `unifi-readonly`.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  local = ../claude-code/skills;
  # Every skill directly under dir.
  skillsIn = dir:
    lib.mapAttrs (skill: _: "${dir}/${skill}")
    (lib.filterAttrs (skill: type: type == "directory" && builtins.pathExists "${dir}/${skill}/SKILL.md")
      (builtins.readDir dir));
in {
  config = lib.mkIf config.programs.codex.enable {
    programs.codex.skills =
      # investigate-first overlaps Matt Pocock's stronger diagnosing-bugs.
      removeAttrs (skillsIn "${inputs.caveman}/skills") ["investigate-first"]
      // lib.mapAttrs (_: path: "${inputs.mattpocock-skills}/skills/${path}") (import ../claude-code/mattpocock-skills.nix)
      // {
        code-review = local + "/code-review";
        humanizer = local + "/humanizer";
        playwright-cli = "${inputs.playwright-cli}/skills/playwright-cli";
        # The Codex build of the skill; plugin/ holds the Claude Code one.
        impeccable = "${inputs.impeccable}/.agents/skills/impeccable";
        i-have-adhd = "${inputs.i-have-adhd}/skills/i-have-adhd";
      }
      # Linux only, like the rea MCP server it drives.
      // lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) {
        reverse-engineer-anything = "${inputs.rea}/.agents/skills/reverse-engineer-anything";
      };
  };
}
