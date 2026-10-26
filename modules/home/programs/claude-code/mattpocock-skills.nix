# Matt Pocock's skills (the mattpocock-skills flake input), linked one by one:
# skill name -> its folder under the input's skills/. settings.nix links them
# for Claude Code and pi, ../codex/skills.nix for Codex.
# Left out on purpose: the issue-tracker pipeline (to-spec, to-tickets,
# implement*, wayfinder, triage, setup-matt-pocock-skills, ask-matt) and his
# code-review, which collides with the local one.
{
  # Interviews. grill-me and grill-with-docs only call the Skill tool, so
  # grilling and domain-modeling come along as their targets.
  grill-me = "productivity/grill-me";
  grilling = "productivity/grilling";
  grill-with-docs = "engineering/grill-with-docs";
  domain-modeling = "engineering/domain-modeling";
  # Engineering disciplines the agent reaches for on its own.
  diagnosing-bugs = "engineering/diagnosing-bugs";
  tdd = "engineering/tdd";
  # Deep-module vocabulary; tdd and improve-codebase-architecture call it.
  codebase-design = "engineering/codebase-design";
  pr = "engineering/pr";
  prototype = "engineering/prototype";
  wizard = "engineering/wizard";
  writing-for-agents = "productivity/writing-for-agents";
  # User-invoked: only a typed /name starts them.
  improve-codebase-architecture = "engineering/improve-codebase-architecture";
  retro = "engineering/retro";
  handoff = "productivity/handoff";
  to-questionnaire = "productivity/to-questionnaire";
  wait-what = "productivity/wait-what";
}
