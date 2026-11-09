# Codex skills, linked into ~/.codex/skills/. That root is Codex's alone:
# ~/.agents/skills would reach pi too, which already gets these through
# claude-bridge. Left out on purpose:
#   - design-taste-frontend, security-audit, brag and brag-slim: settings.nix
#     already links them into ~/.agents/skills, which Codex reads.
#   - context-mode's and ponytail's skills: they come with the plugins
#     (./default.nix).
#   - codex-imagegen: Codex has its own imagegen skill.
#   - pstack: Codex lists every skill to the model, and pstack's adapter only
#     maps Cursor names to Claude Code.
# ./instructions.nix adds `tailwind`, ../unifi/ adds `unifi-readonly`.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  local = ../claude-code/skills;
in {
  config = lib.mkIf config.programs.codex.enable {
    programs.codex.skills =
      lib.mapAttrs (_: path: "${inputs.mattpocock-skills}/skills/${path}") (import ../claude-code/mattpocock-skills.nix)
      // {
        code-review = local + "/code-review";
        council = local + "/council";
        # Claude Code and pi also load ../claude-code/rules/rust/gpui.md on Rust
        # files; Codex has no path-scoped rules, so the description triggers it.
        gpui = local + "/gpui";
        gpui-kit = "${inputs.gpui-kit}/skills/gpui-kit";
        gpui-kit-design-guides = "${inputs.gpui-kit}/skills/gpui-kit-design-guides";
        linear-issue = local + "/linear-issue";
        # The repo root is the skill; Codex reads its agents/openai.yaml too.
        humanizer = "${inputs.humanizer}";
        playwright-cli = "${inputs.playwright-cli}/skills/playwright-cli";
        # The Codex build of the skill; plugin/ holds the Claude Code one.
        impeccable = "${inputs.impeccable}/.agents/skills/impeccable";
        i-have-adhd = "${inputs.i-have-adhd}/skills/i-have-adhd";
        ex-ussr-kinship-research = "${inputs.ex-ussr-kinship-research}";
      }
      # Linux only, like the rea MCP server it drives.
      // lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) {
        reverse-engineer-anything = "${inputs.rea}/.agents/skills/reverse-engineer-anything";
      };
  };
}
