# Storage Reference

This skill writes three targets. `docs/` and `.claude/rules/` are always written. The Obsidian project note is mirrored only when the vault MCPs are available.

Always read `obsidian-memory/SKILL.md` once per session before the Obsidian mirror step — it is the source of truth for vault routing, frontmatter schema, folder skeleton, and naming conventions. This doc only describes code-analyzer's **specialization** of those conventions plus the `docs/` layout.

## 1. `<project>/docs/` — human-readable onboarding (always written)

Detailed, prose-first markdown intended for new collaborators. Generous length is fine — `docs/` is the handbook, not a cheat sheet.

```
docs/
├── README.md          # entry point; links to every other file
├── stack.md
├── dependencies.md
├── architecture.md
├── conventions.md
├── testing.md
├── tooling.md
├── glossary.md        # only if ≥5 domain terms attested
├── onboarding.md
└── change-log.md
```

### Per-file conventions

- **Top-of-file frontmatter** on every file:
  ```yaml
  ---
  generated-by: code-analyzer
  updated: YYYY-MM-DD
  git-sha: <short-sha>
  ---
  ```
- **Writing style:** full sentences, short sections (~5–15 lines each), examples and code snippets where they clarify faster than prose, file-path citations (`path/to/file.ts:12-40`) on every non-trivial claim.
- **Cross-links:** use relative links (`[See conventions.md](./conventions.md#imports)`). `README.md` should link to every other file.
- **Section headers owned by code-analyzer:** every top-level `##` and immediate `###` under it. Anything outside those headers is "manual content" and must be preserved across re-runs.
- **No raw tool dumps.** Summarize and cite; don't paste whole `package.json` or dependency trees.

### `README.md` skeleton

```markdown
---
generated-by: code-analyzer
updated: YYYY-MM-DD
git-sha: <short-sha>
---

# <Project Name>

One-paragraph description: what the project is and who it's for.

## Quick map

- **[Stack](./stack.md)** — languages, frameworks, runtimes, build tools
- **[Dependencies](./dependencies.md)** — notable libraries and why they matter
- **[Architecture](./architecture.md)** — layout, data flow, request lifecycle
- **[Conventions](./conventions.md)** — code style, naming, file organization
- **[Testing](./testing.md)** — how tests are organized and run
- **[Tooling](./tooling.md)** — lint, typecheck, format, CI
- **[Glossary](./glossary.md)** — domain vocabulary
- **[Onboarding](./onboarding.md)** — get from clone to first PR
- **[Change log](./change-log.md)** — history of analyzer runs

## At a glance
- Language: <lang> <version>
- Framework: <framework> <version>
- Runtime: <runtime>
- Deployment: <where>

## Status
Last analyzed: <YYYY-MM-DD>, git SHA `<short-sha>`.
```

### `onboarding.md` template

```markdown
# Onboarding

Step-by-step for a new contributor on an empty machine.

## 1. Prerequisites
- <runtime + version>
- <package manager>
- <any required services, e.g. Postgres, Redis>

## 2. Clone & install
```bash
git clone <repo>
cd <project>
<install command>
```

## 3. Environment
Copy `.env.example` to `.env.local` and fill:
- `<VAR>` — <purpose>, obtain from <source>

## 4. Run locally
```bash
<dev command>
```

## 5. Run tests
```bash
<test command>
```

## 6. Your first task
Good starter tasks live in <location>. Before opening a PR, run:
```bash
<lint + typecheck + test commands>
```
```

### `change-log.md` format

Reverse-chronological. New entries at the top. Each entry records added / removed / changed findings by category — this is how collaborators see the codebase's evolution.

```markdown
---
generated-by: code-analyzer
updated: YYYY-MM-DD
git-sha: <short-sha>
---

# Change Log

### YYYY-MM-DD — code-analyzer run (git <short-sha>)
**Stack:** + Turbopack; removed Webpack config.
**Dependencies:** bumped `next` 15.0 → 16.1; added `@ai-sdk/react`.
**Architecture:** moved auth into middleware (previously per-route).
**Testing:** no change.
**Tooling:** switched from eslint to biome.
```

## 2. `<project>/.claude/rules/` — AI-agent rules (always written)

Terse, rule-shaped guidance for future Claude sessions. See [rule-templates.md](rule-templates.md) for exact templates.

```
.claude/rules/
├── stack.md
├── coding-style.md
├── patterns.md
├── testing.md
├── tooling.md
└── glossary.md
```

Each rule file points to its `docs/` counterpart as the source of truth for depth:

```markdown
> Full context: [`docs/stack.md`](../../docs/stack.md).
> Rules below are the compressed, AI-facing summary.
```

Also write at project root:
- `AGENTS.md` — AI-agnostic pointer file.
- `CLAUDE.md` — one-line pointer to `AGENTS.md`.

## 3. Obsidian project note — mirror (only when MCPs available)

**code-analyzer does NOT define its own Obsidian template.** All vault routing, frontmatter schema, folder skeleton, project-note template, and hub-maintenance rules live in `~/.claude/skills/obsidian-memory/SKILL.md`. Read that file once per session and defer to it for every vault write.

Obsidian is a condensed mirror (~200 lines), not a second copy of `docs/`. Full prose stays in `docs/`.

### What code-analyzer is responsible for

- Populating each canonical section of obsidian-memory's **Canonical Project Note Template** from the Phase 2 category payloads (see target-name map in `SKILL.md`).
- Setting the frontmatter fields code-analyzer owns: `type: project`, `status: active`, `source: observed`, `confidence: high`, plus appending `code-analyzer` + primary-language + framework to `tags`. An optional `git-sha: <short-sha>` is permitted for analyzer-authored notes.
- Adding the line `Full onboarding docs: [repo path]/docs/README.md` near the top of the note.
- Appending a dated entry to the note's `## Change Log` section — one line per Phase 2 category, mirroring `docs/change-log.md`.
- Updating `_hub.md` in the routed vault per obsidian-memory's Hub Maintenance protocol on every create/rename/archive.

### What obsidian-memory owns (do not duplicate here)

- Vault routing table (personal vs boundary)
- Folder skeleton (`People/`, `Projects/`, `Entities/`, `Preferences/`, `Decisions/`, `Procedures/`, `Context/`, `Journal/`)
- Frontmatter schema (`type`, `status`, `confidence`, `source`, `created`, `updated`, `related`, `tags`)
- Canonical Project Note Template headings and order (`## Summary`, `## Stack`, `## Repo & Deployment`, `## Environment`, `## Architecture Notes`, `## API & Integrations`, `## Known Issues & Gotchas`, `## Decisions`, `## People`, `## Change Log`)
- Hub Maintenance protocol and canonical hub skeleton
- Note-naming conventions and atomicity rules

If any guidance in this file appears to conflict with `obsidian-memory/SKILL.md`, obsidian-memory wins — fix this file.

### Drill-down sub-notes

When a category deserves a deep dive beyond the 200-line mirror (e.g., 11 architectural patterns), emit a sub-note at `Projects/<Name>/<Topic>.md`. Sub-note frontmatter must use obsidian-memory's canonical schema:

```yaml
type: fact
status: active
confidence: high
source: observed
related:
  - "[[Projects/<Name>]]"
tags:
  - code-analyzer
  - <topic>
```

Link every sub-note from the hub project note's relevant canonical section. Do not list sub-notes in `_hub.md` — only the project hub appears there.

## Idempotency rules (all targets)

1. **Always read before writing.** For `docs/` and `.claude/rules/`, `Read` each file. For Obsidian, `read_note`. Preserve manual content outside code-analyzer-owned section headers.
2. **Overwrite, don't append** the sections this skill owns — avoids drift across re-runs.
3. **Change logs are append-only at the top** of their section.
4. **Frontmatter `updated` and `git-sha` bump on every write.** `created` bumps only on first write.
5. **Stub missing Obsidian related-notes.** If `related` references a `[[People/...]]` or `[[Entities/...]]` note that doesn't exist, create a minimal stub per `obsidian-memory` conventions.
6. **Never `delete_note`.** Archive via frontmatter `status: archived` on explicit user request.

## What this skill does NOT do

- Does not create per-category Obsidian notes — mirror lives in the single project note.
- Does not touch `_hub.md`, `Journal/`, `Decisions/`, or `Procedures/` in the vault (leave those to `obsidian-memory`).
- Does not write to both Obsidian vaults — exactly one vault per project.
- Does not modify project source code, config, or lockfiles. Read-only on the repo.
