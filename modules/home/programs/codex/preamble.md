# Codex on this machine

Nix generates this file from `~/.nixfiles/modules/home/programs/codex/`. To
change Codex's instructions, skills, agents, hooks or MCP servers, edit that
folder and run `rebuild_system`. Never edit `~/.codex/AGENTS.md`,
`~/.codex/agents/`, `~/.codex/skills/` or `~/.codex/hooks.json` by hand.
`~/.codex/config.toml` stays writable, and each rebuild merges the declared
keys back into it.

If Codex offers to import the Claude Code configuration, decline. Nix already
ported it, and the import would write files that Nix owns.

## Reading rules written for Claude Code

The rules below are shared with Claude Code and use its names. In Codex:

- "Agent tool", "subagent", or a named agent (planner, code-reviewer,
  security-reviewer, architect and the rest) means the Codex
  subagent of that name, defined in `~/.codex/agents/`.
- "Skill tool" or "load the X skill" means invoking the skill as `$X`.
- AskUserQuestion means asking the user in chat.
- Plan Mode means `/plan`.
- `settings.nix`, `permissions.allow`, Claude Code hooks and
  `~/.claude/settings.json` configure Claude Code and do nothing here.
- Files under `~/.claude/` that rules, skills or agents point to (rules,
  CLAUDE.md files) exist on disk and can be read.

## Guards Claude Code enforces with hooks

Codex has no hook for these, so follow them yourself:

- Before you write or send human-facing text, invoke `$humanizer` (see
  "Human-Facing Text" below).
- Never edit a file whose real path is under `/nix/store`. Edit the Nix
  source that produces it, usually under `~/.nixfiles/`.
- Search the web with the `searxng` MCP server's `searxng_web_search`, and
  read a page with its `web_url_read`. Codex's built-in web search is off.

## Tailwind

The Tailwind rules are the `tailwind` skill. Invoke `$tailwind` before you
write or review CSS, or styled markup in .tsx, .jsx, .html, .vue, .svelte,
.astro or .mdx files.

## Output style

The reader has ADHD. Shape every response so it can be acted on:

1. Lead with the answer or next action: command, path, or snippet first.
2. Number multi-step work; one bounded action per step.
3. End with one next action doable in under two minutes.
4. Finish the current issue before raising a new one.
5. Restate progress each turn ("step 3 of 5 done").
6. Give time estimates in concrete units, never "a bit".
7. After a change, show what now works.
8. Errors: state location, cause, and fix. No drama.
9. Cap lists to 5 items.
10. No preamble, no recaps, no closers.

Exceptions: explain fully when asked to explain. Confirm before destructive actions. After three failed fixes, stop and name the doubtful assumption. If the request is ambiguous, ask one short question.
