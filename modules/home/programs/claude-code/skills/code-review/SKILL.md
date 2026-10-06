---
name: code-review
description: >
  Reviews code at the scope the context calls for. By default it reviews the change in front of
  you as a senior pre-merge gate: inside Ensemblr that is the workspace diff the Changes panel
  shows (the Review button lands here), elsewhere the whole branch against its base plus
  uncommitted work, uncommitted work alone when asked, or a GitHub PR by number. It switches to a
  codebase-wide architectural review (deep vs shallow modules, coupling, smells, refactoring
  roadmap) only when the user explicitly asks for the whole codebase, a directory or a module's
  design. Trigger on "review this", "review my changes", "review the diff", "review before
  commit", "review the branch", "review before PR", "is this ready to merge", "PR-readiness
  check", "audit the codebase", "is this good architecture", "refactor suggestions", "code
  quality", "module design", or pasted code with "what do you think?".
---

# Code Review

One review skill with two modes. This file picks the mode from the context and names the file
that carries that mode's instructions. Read exactly that one file before you start.

## Pick the mode

| Signal | Mode | Read |
|--------|------|------|
| The user explicitly asks for the whole codebase, a directory or a module's design: "review the codebase", "audit the architecture", "is `src/billing` well structured?", "refactor suggestions for this module" | Codebase | `references/codebase-review.md` |
| Anything else: Ensemblr's Review button, "review this", "review my changes", "review the branch", "ready for PR?", a PR number | Change | `references/change-review.md` |

At the boundary:

- **Change mode is the default.** Inside Ensemblr, "review" with no other scope means the
  workspace diff.
- **A codebase review needs an explicit ask.** A vague "review my code" while a diff exists is a
  change review.
- **Change mode finds nothing to review**: say so and offer a codebase review. Do not start one.
- **Pasted code or one named file**: review that code directly. Use `references/smells.md` for
  depth, and skip the scope steps.
- **Both asked** ("review my branch, and does the module design hold up?"): run the change review
  first. Then run codebase mode, limited to the modules the change touches.

## Ground rules for both modes

- The repository's own conventions come first: `CLAUDE.md`, `AGENTS.md`, `.cursorrules`, rule
  files and any review instructions it ships. Match its established patterns rather than
  imposing generic preferences.
- Report only what you are more than 80% confident is a real problem. Consolidate similar
  findings, and skip stylistic noise.
- Every finding names a location, its concrete cost and a concrete fix.
- When the code is clean, say so plainly and briefly. Don't invent problems to look thorough.
- A review does not change code. Fix only when the user, or the workflow driving you, asks.

## Related agents and skills

Delegate through the Agent tool where it exists, one call per concern. Inside Ensemblr, follow
the playbook's delegation rules instead.

- **`code-reviewer`** — the senior reader change mode briefs for each slice of a wide diff.
  Its checklist lives in `~/.claude/agents/code-reviewer.md`.
- **`security-reviewer`** — when either mode surfaces auth, input handling, secrets or any
  OWASP-adjacent concern. Hand off the specific files and let it produce its own report; do not
  inline its checks here.
- **`refactor-cleaner`** — once codebase mode has named the targets and the user wants the
  dead-code and duplicate consolidation pass executed.
- **`database-reviewer`** — for any Postgres or Supabase schema or query findings.
