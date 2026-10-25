# ~/.codex/AGENTS.md: ./preamble.md, then the Claude Code rules
# (../claude-code/rules/). Codex has no path-scoped rules, so the TypeScript
# rules go in under a heading that scopes them, and the 11 KB Tailwind rules
# become the `tailwind` skill instead. Both hooks.md rules stay out: they
# describe Claude Code settings.
#
# preamble.md's "Output style" section is i-have-adhd's always-on snippet for
# Codex, from its INSTALL.md.
{
  config,
  lib,
  pkgs,
  ...
}: let
  rules = ../claude-code/rules;
  # Prints a markdown file without its leading frontmatter block.
  strip = ''
    strip() { awk 'NR == 1 && $0 == "---" {fm = 1; next} fm && $0 == "---" {fm = 0; next} !fm' "$1"; }
  '';

  agentsMd = pkgs.runCommand "codex-AGENTS.md" {} ''
    ${strip}
    {
      cat ${./preamble.md}
      for f in ${rules}/common/*.md ${rules}/web/defaults.md; do
        [ "''${f##*/}" = hooks.md ] && continue
        echo
        strip "$f"
      done
      echo
      echo "# TypeScript and JavaScript"
      echo
      echo "The rules in this section apply only when the task touches .ts, .tsx, .js or .jsx files."
      for f in ${rules}/typescript/*.md; do
        [ "''${f##*/}" = hooks.md ] && continue
        echo
        strip "$f"
      done
    } > "$out"
    if grep -q '^paths:' "$out"; then
      echo "codex: a rule kept its frontmatter" >&2
      exit 1
    fi
  '';

  tailwindFrontmatter = pkgs.writeText "codex-tailwind-frontmatter" ''
    ---
    name: tailwind
    description: "The user's Tailwind CSS rules: v4, rem lengths, scale tokens over arbitrary values, theme extension, and composing classes with cn(). Use when writing, editing or reviewing CSS, or styled markup in .tsx, .jsx, .html, .vue, .svelte, .astro or .mdx files."
    ---
  '';
  tailwindSkill = pkgs.runCommand "codex-tailwind-SKILL.md" {} ''
    ${strip}
    { cat ${tailwindFrontmatter}; strip ${rules}/web/tailwind.md; } > "$out"
  '';
in {
  config = lib.mkIf config.programs.codex.enable {
    # Not programs.codex.context: that writes a store path given as a string
    # as the file's text.
    home.file.".codex/AGENTS.md".source = agentsMd;
    programs.codex.skills.tailwind = tailwindSkill;
  };
}
