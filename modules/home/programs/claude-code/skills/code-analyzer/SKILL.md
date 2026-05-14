---
name: code-analyzer
description: Analyzes an existing codebase end-to-end to extract its stack, dependencies, architectural patterns, code style, naming conventions, testing approach, tooling, and domain vocabulary. Persists structured findings to the Obsidian vault via the obsidian-memory skill, and generates a project-specific `.claude/rules/` set so future Claude sessions instantly understand the project. Use this skill whenever the user wants to onboard Claude to a new or unfamiliar repository, "learn" or "understand" a project, audit its stack, document conventions, generate project rules, or whenever they say things like "analyze this codebase", "scan the project", "set up Claude for this repo", "extract the conventions", "what's the stack here", "make rules for this project", or has just cloned/joined a repo. Trigger proactively when the user opens an unknown codebase and asks Claude broad questions about how it works, even if they don't explicitly say "analyze".
---

# Code Analyzer

Run a structured discovery pass over a codebase, distill findings into the Obsidian memory vault, and emit project-specific rules so future AI coding sessions inherit the context.

## Outputs

Every run always produces three things, regardless of environment:

1. **`docs/` — human-readable onboarding docs.** Rich, detailed markdown written to the project root so any collaborator (human or AI) can navigate the codebase quickly. This is the primary deliverable.
2. **`.claude/rules/` — AI-agent rules.** Concise, rule-shaped guidance for future Claude sessions working in this repo.
3. **Project-root `README.md`, `AGENTS.md`, `CLAUDE.md`.** The root README gets a fenced, regenerated "at a glance" block (manual content is preserved outside the fence). `AGENTS.md` is the AI-agnostic entry point. `CLAUDE.md` is a one-line pointer to `AGENTS.md`.

Optionally, when the Obsidian vault MCPs are available, the skill **also** mirrors the key findings into the project's Obsidian note by delegating to the `obsidian-memory` skill. That gives Philipp cross-project memory continuity on top of the in-repo `docs/`.

### Delegation to obsidian-memory (MANDATORY)

code-analyzer does **not** define its own Obsidian frontmatter, folder layout, project-note template, or hub-maintenance rules. Those all live in `~/.claude/skills/obsidian-memory/SKILL.md` and are the single source of truth.

On every run where Obsidian MCPs are available:

1. **Read `obsidian-memory/SKILL.md` once per session** before any vault write. Load its Canonical Project Note Template, Frontmatter Schema, Vault Routing table, Folder Skeleton, and Hub Maintenance protocol into working memory.
2. Use obsidian-memory's **exact Canonical Project Note Template headings** (`## Summary`, `## Stack`, `## Repo & Deployment`, `## Environment`, `## Architecture Notes`, `## API & Integrations`, `## Known Issues & Gotchas`, `## Decisions`, `## People`, `## Change Log`). Do not invent or rename sections. Populate each section from the Phase 2 category findings per the target-name map below.
3. Use obsidian-memory's **Frontmatter Schema** verbatim. Do not introduce parallel fields. code-analyzer is responsible only for populating `type: project`, `status: active`, `source: observed`, `confidence: high`, and appending `code-analyzer` + primary-language + framework to `tags`.
4. Call `write_note` via the vault MCPs — never hand-write YAML into the body.
5. **Update `_hub.md`** in the routed vault on every create/rename/archive per obsidian-memory's Hub Maintenance protocol. Non-negotiable.

If any of the above conflicts with a rule in `obsidian-memory/SKILL.md`, **obsidian-memory wins**. Fix code-analyzer to match.

- **Obsidian MCPs available** (`mcp__obsidian-personal__*` and `mcp__obsidian-boundary__*`): write `docs/` + `.claude/rules/` + mirror into Obsidian via the delegation protocol above.
- **Obsidian MCPs unavailable or erroring**: write `docs/` + `.claude/rules/` only. Tell the user the Obsidian mirror was skipped and why.

`docs/` is never skipped. It is the canonical, in-repo source of truth for collaborators.

## Target-name map

The same seven categories surface under three different filenames depending on target. Use this table when generating or reconciling files — a category name in Phase 2 is NOT necessarily the filename in Phase 3 or 4.

The Obsidian section column maps a Phase 2 category to its target heading inside obsidian-memory's Canonical Project Note Template. Multiple categories may fold into a single canonical section — don't add new sections; layer content under the canonical headings with `###` sub-headings where needed.

| Phase 2 category | Reference doc              | `docs/` file          | `.claude/rules/` file | Obsidian canonical section |
|------------------|----------------------------|-----------------------|-----------------------|---------------------------|
| stack            | `references/stack.md`      | `stack.md`            | `stack.md`            | `## Stack`                |
| dependencies     | `references/dependencies.md` | `dependencies.md`   | *(rolled into stack)* | `## Stack` → `### Dependencies` sub-block |
| patterns         | `references/patterns.md`   | `architecture.md`     | `patterns.md`         | `## Architecture Notes`   |
| style            | `references/style.md`      | `conventions.md`      | `coding-style.md`     | `## Architecture Notes` → `### Conventions` sub-block (or a project-specific `## Style` only if obsidian-memory adds it) |
| testing          | `references/testing.md`    | `testing.md`          | `testing.md`          | `## Architecture Notes` → `### Testing` sub-block |
| tooling          | `references/tooling.md`    | `tooling.md`          | `tooling.md`          | `## Environment` (commands) + `## Architecture Notes` → `### Tooling` |
| domain           | `references/domain.md`     | `glossary.md`         | `glossary.md`         | `## Architecture Notes` → `### Domain Glossary` (only if ≥5 terms) |

Three additional `docs/` files have no Phase 2 category — they are generated from the synthesis itself: `README.md` (index), `onboarding.md` (clone → first PR runbook), `change-log.md` (run history). See [references/storage.md](references/storage.md) for their templates.

The canonical internal JSON shape for each category (envelope + per-category `findings`) lives in [references/schemas.md](references/schemas.md). Hold findings in memory in that shape so prose/rules/Obsidian stay consistent across all three targets.

## When to use

Invoke when the user wants Claude to *learn a codebase*. Typical triggers:
- "Analyze this repo / codebase / project"
- "Set up Claude for this project"
- "Generate project rules"
- "What's the stack / patterns / conventions here?"
- They just cloned a repo and are asking broad questions about it
- They want a baseline before refactoring or adding features

If the user only asks about *one* specific file or function, this skill is overkill — just answer directly.

## High-level workflow

Five-phase pipeline. Each phase has its own reference doc — read it when you reach that phase.

```
0. ORIENT    → Detect MCP availability, pick vault routing, check for prior docs
1. DISCOVER  → Inventory files, lockfiles, configs, top-level shape
2. ANALYZE   → Extract stack, patterns, style, testing, tooling, domain
3. SYNTHESIZE → Write rich human-readable docs/ (always) + mirror to Obsidian (if available)
4. EMIT      → Write `.claude/rules/` files in the project root
```

Do NOT skip phases. Each downstream phase depends on the structure established earlier.

**Persistent storage:**
- **Always:** `<project>/docs/` — detailed, human-readable onboarding docs (one file per category plus a `README.md` index).
- **When Obsidian MCPs are available:** mirror the same findings into `Projects/<Project Name>.md` in the routed vault (per `obsidian-memory`).

See [references/storage.md](references/storage.md) for both layouts and vault-routing rules.

## Phase 0 — Orient

Before touching the codebase, establish storage context:

1. **Probe Obsidian MCP availability.** Try a cheap call on each vault (e.g. `get_vault_stats`). If both respond, set `obsidianMirror = true`. Otherwise `obsidianMirror = false`. Either way, `docs/` will still be written.
2. Derive the canonical project name from `package.json#name`, `pyproject.toml#project.name`, `Cargo.toml#package.name`, repo folder, or `git remote`.
3. **If `obsidianMirror`, determine vault routing** per `obsidian-memory/SKILL.md`. Do not restate the rules here — defer to that skill for routing, frontmatter schema, and folder conventions. Default to `obsidian-personal` when unsure and confirm with the user.
4. **Check for prior analysis** in both places (so updates merge, not duplicate):
   - Read `<project>/docs/README.md` if it exists and looks code-analyzer-owned (`generated-by: code-analyzer` frontmatter).
   - If `obsidianMirror`: `search_notes` on the chosen vault with the project name, also `searchFrontmatter: true` with `type: project`. If found, `read_note`.
5. If prior findings exist, ask: "Prior analysis from `<updated date>` exists in `<docs/ and/or Obsidian>`. Refresh fully, update incrementally, or use as-is?"
6. If no prior data, proceed to Phase 1.

Record the storage mode (`obsidianMirror` + vault prefix) and canonical note path for every later write.

## Phase 1 — Discover

Goal: get a fast, high-signal map of what's in the repo *before* reading any source code in depth.

Read [references/discovery.md](references/discovery.md) for the full file inventory checklist (lockfiles, manifests, config, CI, container files, framework markers).

Cheap, high-signal moves:
- `git ls-files | head -200` — what's tracked
- Look for: `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile`, `composer.json`, `pom.xml`, `build.gradle`
- Look for: `.editorconfig`, `.prettierrc*`, `.eslintrc*`, `biome.json`, `ruff.toml`, `.rubocop.yml`, `tsconfig.json`
- Look for: `Dockerfile`, `docker-compose.*`, `.github/workflows/`, `turbo.json`, `nx.json`, `pnpm-workspace.yaml`
- Top-level directory listing (1-2 levels deep) to get the layout

Hold the inventory in working memory for this session only — do NOT persist it to Obsidian. It's raw input to Phase 2, not a durable finding.

## Phase 2 — Analyze

Run the seven extraction passes. Each has a dedicated reference doc:

| Category | Reference | What it captures |
|---|---|---|
| Stack | [references/stack.md](references/stack.md) | Languages, frameworks, runtimes, package managers, build tools |
| Dependencies | [references/dependencies.md](references/dependencies.md) | Key libs, versions, dev vs prod, notable choices |
| Patterns | [references/patterns.md](references/patterns.md) | Architectural style, layering, monorepo shape, API style |
| Style | [references/style.md](references/style.md) | Indent, naming, imports, formatter config, file organization |
| Testing | [references/testing.md](references/testing.md) | Framework, test layout, coverage approach, CI test invocation |
| Tooling | [references/tooling.md](references/tooling.md) | Linters, type checkers, git hooks, CI providers, scripts |
| Domain | [references/domain.md](references/domain.md) | Recurring business terms, key entities, glossary |

**Important — sample, don't enumerate.** For style and patterns, read 5–15 *representative* files (one per major directory or feature) rather than every file. The goal is fast convergence on conventions, not exhaustive cataloguing.

**Important — verify via Context7 during analysis, not after.** As soon as Stack + Dependencies detect a framework/library/runtime, resolve its Context7 ID and keep it handy. Every downstream category pass (Patterns, Style, Testing, Tooling) that references framework-level behavior must `query-docs` on the relevant topic before emitting a claim. See the Context7 verification protocol at the bottom of this skill. The Next.js 16 `middleware.ts` → `proxy.ts` rename is the canonical failure mode — do not describe a Next.js project's middleware from memory.

Each category produces one **`docs/` file** (human-readable onboarding page) and, if `obsidianMirror`, one **section** inside the Obsidian project note. The per-category reference docs describe what to capture. Hold all seven category payloads in working memory — shaped per [references/schemas.md](references/schemas.md) — until Phase 3, where you write them in a coordinated pass.

See [references/storage.md](references/storage.md) for the full `docs/` layout, frontmatter schema, and Obsidian project-note structure. Use the target-name map at the top of this file to translate a Phase 2 category to its output filename before writing.

## Phase 3 — Synthesize

Write human-readable onboarding docs first, then (optionally) mirror into Obsidian.

### 3a. Always — write `<project>/docs/`

Goal: any new collaborator can land in the repo, open `docs/README.md`, and be productive within an hour. Be generous with prose, examples, and cross-links — this is NOT a terse rules file.

Create/update these files (skip any whose category findings were too sparse):

```
<project>/docs/
├── README.md          # entry point: project overview, how to read the rest
├── stack.md           # languages, frameworks, runtimes, build tools — with context on why
├── dependencies.md    # notable libraries grouped by role; versions; quirks
├── architecture.md    # layout, layering, data flow, request lifecycle, diagrams if useful
├── conventions.md     # code style, naming, file organization, import ordering
├── testing.md         # how tests are organized, how to run them, coverage approach
├── tooling.md         # lint/typecheck/format/CI commands; how to run each locally
├── glossary.md        # domain vocabulary (only if ≥5 terms attested)
├── onboarding.md      # step-by-step: clone → env → install → run → first task
└── change-log.md      # reverse-chronological log of code-analyzer runs
```

Separately, the **project-root `README.md`** (one level above `docs/`) is also written/updated on every run via a fenced region — see [Phase 4 → Root `README.md`](#root-readmemd--generate-or-update). Do not confuse it with `docs/README.md` above, which is the onboarding index.

Rules for `docs/` content:
- Write for a smart new hire, not a compiler. Full sentences, examples, "why" alongside "what".
- Cite file paths (`path/to/file.ts:12-40`) for every non-trivial claim so readers can verify.
- Include code snippets (5–20 lines) where they illustrate a pattern faster than prose.
- Cross-link liberally: `[See conventions.md](./conventions.md#imports)`.
- Don't be afraid of length — detail beats brevity here. `docs/` is the handbook.
- Do NOT paste the full output of a tool (no whole `package.json` dumps); summarize + cite.

Frontmatter on every file — canonical schema lives in [references/storage.md](references/storage.md#per-file-conventions). Bump `updated` and `git-sha` on every write; `created` (Obsidian only) bumps on first write only.

### Generating `README.md`, `onboarding.md`, `change-log.md`

These three files are synthesized from the Phase 2 findings rather than mapped 1:1 from a category. Use the templates in [references/storage.md](references/storage.md) and populate as follows:

- **`README.md`** — the `## At a glance` block pulls from the `stack` findings (primary language + version, framework + version, runtime, deployment target if detected from `CONTAINERS`/`vercel.json`/`wrangler.toml`/CI). The `## Quick map` list links to every other `docs/` file that was actually written this run — skip links to files you didn't create (e.g., `glossary.md` when <5 domain terms). The one-paragraph project description comes from the repo root `README*` file if present, otherwise from `package.json#description` / `pyproject.toml#project.description` / Cargo equivalent.
- **`onboarding.md`** — populate prereqs from `stack` (runtime versions) and `tooling` (package manager). Fill the install / dev / test / lint commands from `tooling.scripts` and `testing.commands`. Read `.env.example` / `.env.sample` if present and list each variable with a one-line purpose. If none exists, omit the Environment section rather than inventing variables.
- **`change-log.md`** — on first run, write a single initial-analysis entry. On every subsequent run, prepend the dated diff entry produced in the reconciliation step (Phase 4 re-run rules).

When updating any `docs/` file, `Read` it first. Overwrite only the `##` sections code-analyzer owns (listed in the file's template); preserve any manual sections in between. For `README.md` specifically, the `## Quick map` and `## At a glance` blocks are owned sections — anything under a non-template heading stays untouched.

Change-log entry format:

```markdown
### YYYY-MM-DD — code-analyzer run (git <short-sha>)
**Stack:** <added / removed / changed, or "no change">.
**Dependencies:** <…>.
**Architecture:** <…>.
**Conventions:** <…>.
**Testing:** <…>.
**Tooling:** <…>.
**Domain:** <…>.
```

Omit categories that didn't re-run this pass.

### 3b. If `obsidianMirror` — delegate the mirror to obsidian-memory

Mirror the condensed findings into `Projects/<Project Name>.md` in the routed vault so cross-project memory continuity works. This is a distilled mirror, not a duplicate of `docs/` — aim for ~200 lines in the Obsidian note, with the full prose living in `docs/`.

**code-analyzer does not own the Obsidian note structure.** Follow `obsidian-memory/SKILL.md` verbatim:

1. **Re-read `obsidian-memory/SKILL.md`** if not already loaded this session. Use its Canonical Project Note Template, Frontmatter Schema, Vault Routing, and Hub Maintenance rules without deviation.
2. **Target path**: `Projects/<Project Name>.md` in the routed vault (see obsidian-memory Vault Routing).
3. **Read before write.** `read_note` the existing note (if any) and preserve manual content outside canonical headings. Preserve the existing `created` frontmatter date; only bump `updated`.
4. **Populate the Canonical Project Note Template** section-by-section from the Phase 2 category payloads using the target-name map at the top of this skill. If a category payload is too sparse for a section, leave the section as `_TBD_` — do not drop the heading.
5. Near the top of the note, add: `Full onboarding docs: [repo path]/docs/README.md`.
6. `write_note` (mode `overwrite`) with full frontmatter via the `frontmatter` parameter. Required fields: `type: project`, `status: active`, `confidence: high`, `source: observed`, `created`, `updated`, `related`, `tags` (include `code-analyzer`, primary language, and framework). Add the optional `git-sha: <short-sha>` for code-analyzer-authored notes.
7. **Append a Change Log entry** under `## Change Log` at the top of the reverse-chronological list using the format in `docs/change-log.md` (condensed to one line per category).
8. **Update `_hub.md`** in the same vault per obsidian-memory's Hub Maintenance protocol — add/update the project bullet under `### Projects` of `## Current Notes` and bump the hub's `updated` date. Non-negotiable.
9. **Stub missing related notes.** If `related` references a `[[People/...]]` or `[[Entities/...]]` note that doesn't exist, create a minimal stub per obsidian-memory conventions and add it to `_hub.md`.

If `obsidianMirror` was false, skip 3b entirely and tell the user the mirror was skipped.

**Drill-down sub-notes** (e.g., `Projects/<Name>/Stack.md`, `Projects/<Name>/Patterns.md`) are allowed when a category deserves its own deep dive. Sub-note frontmatter must use obsidian-memory's canonical schema (`type: fact`, `status: active`, `source: observed`, with `related: [[Projects/<Name>]]`). Link every sub-note from the hub project note's relevant canonical section, and from `_hub.md` only via the project bullet (do not list every sub-note in the hub).

Resolve conflicts: if two signals disagree (e.g., `.prettierrc` says 2-space but most files use 4), record both and prefer the **observed** behavior over the **declared** config — actual code wins because it reflects what the team actually does.

## Phase 4 — Emit project rules

Generate `.claude/rules/` files in the project root, mirroring the user's global rule structure but populated from findings. Use [references/rule-templates.md](references/rule-templates.md) for the templates.

Files to generate (only include what's relevant — skip categories where findings were too sparse):
- `.claude/rules/stack.md` — what the project uses and why
- `.claude/rules/coding-style.md` — concrete conventions observed
- `.claude/rules/patterns.md` — architectural and design patterns
- `.claude/rules/testing.md` — how tests are organized and run
- `.claude/rules/tooling.md` — how to run lint/typecheck/format
- `.claude/rules/glossary.md` — domain terms (only if domain pass found ≥5 terms)

Do NOT duplicate rules from the user's global `~/.claude/rules/common/`. If a project rule would just restate a global one, omit it. Only emit project-specific guidance.

### Root `README.md` — generate or update

The project-root `README.md` (not `docs/README.md`) is the first thing a visitor sees on GitHub/GitLab. The analyzer owns a single fenced region inside it; everything outside the fence is manual content and must survive every re-run untouched.

**Owned region format.** Use HTML comment fences so manual edits never collide:

```markdown
<!-- code-analyzer:start — do not edit inside this block; regenerated on every run -->
...owned content...
<!-- code-analyzer:end -->
```

**Owned content layout** (inside the fence):

```markdown
> Generated by the code-analyzer skill — `updated: YYYY-MM-DD`, git `<short-sha>`.

## At a glance
- **Language:** <primary language + version>
- **Framework:** <framework + version>  (omit if none)
- **Runtime:** <runtime + version>
- **Package manager:** <pm + version>
- **Deployment:** <platform>  (omit if unknown)

## Quick start
```bash
<install command>
<dev command>
```
Full setup in [`docs/onboarding.md`](./docs/onboarding.md).

## Docs & rules
- Human docs: [`docs/README.md`](./docs/README.md)
- AI-agent rules: [`.claude/rules/`](./.claude/rules/)
- AI entry point: [`AGENTS.md`](./AGENTS.md)
```

**Generation flow:**

1. **If no `README.md` exists at project root:** create one. Put the project name as `# <Name>` on line 1, a one-line description on line 3 (sourced from `package.json#description` / `pyproject.toml#project.description` / Cargo equivalent, or `<add a description>` placeholder if none), then an empty line, then the fenced owned region above. Nothing else.
2. **If `README.md` exists and contains `<!-- code-analyzer:start -->`:** replace the existing fenced block in-place. Leave the rest of the file byte-identical.
3. **If `README.md` exists but has no fence:** do not overwrite. Instead, append the fenced region at the bottom of the file with one blank line before it, and tell the user the skill added its block at the end so they can move it if they prefer.
4. **Never delete or rewrite manual content.** If the user renames `## At a glance` to `## Overview`, respect it — the fence is the only thing the skill owns.

Populate each line from Phase 2 findings: `At a glance` from `stack`, `Quick start` commands from `tooling.scripts`, deployment from `CONTAINERS` / `vercel.json` / `netlify.toml` / `wrangler.toml` signals. Omit a bullet if the finding is unknown rather than writing `<tbd>`.

### `AGENTS.md` and `CLAUDE.md`

After writing, ensure the project has an `AGENTS.md` at the root (the AI-agnostic convention) with a pointer to the rules. Create it if missing, or prepend the pointer if it already exists:

```markdown
> Onboarding docs: [`docs/README.md`](./docs/README.md) (human-readable).
> AI-agent rules: [`.claude/rules/`](./.claude/rules/) (terse, rule-shaped).
> Generated and kept in sync by the code-analyzer skill.
```

For backwards compatibility with tools that still look for `CLAUDE.md`, create a minimal `CLAUDE.md` that simply points to `AGENTS.md`:

```markdown
> See [AGENTS.md](./AGENTS.md) for project instructions.
```

If `CLAUDE.md` already exists with real content, migrate that content into `AGENTS.md` first, then replace `CLAUDE.md` with the one-line pointer above. Confirm with the user before overwriting any existing `CLAUDE.md` that isn't already a pointer.

## Storage layout

Three persistence targets, all written on every run (Obsidian is optional):

**1. Human-readable onboarding docs — always written:**

```
<project>/docs/
├── README.md          # entry point + how to navigate
├── stack.md
├── dependencies.md
├── architecture.md
├── conventions.md
├── testing.md
├── tooling.md
├── glossary.md        # only if ≥5 domain terms attested
├── onboarding.md      # clone → env → run → first task
└── change-log.md      # reverse-chronological analyzer runs
```

Rich prose, examples, file citations. Intended for new collaborators.

**2. AI-agent rules & project-root files — always written:**

```
<project>/
├── .claude/
│   └── rules/
│       ├── stack.md
│       ├── coding-style.md
│       ├── patterns.md
│       ├── testing.md
│       ├── tooling.md
│       └── glossary.md
├── README.md           # fenced owned region + any manual content preserved
├── AGENTS.md           # primary, AI-agnostic instructions file
└── CLAUDE.md           # one-line pointer to AGENTS.md (backwards compatibility)
```

Terse, rule-shaped. `AGENTS.md` points to both `.claude/rules/` and `docs/`. The root `README.md` gets a regenerated `<!-- code-analyzer:start -->` / `<!-- code-analyzer:end -->` block; everything outside that fence is manual and preserved verbatim across re-runs.

**3. Obsidian project note — written only when MCPs available:**

| Path | Vault | Owner | Frontmatter `type` |
|---|---|---|---|
| `Projects/<Project Name>.md` | `obsidian-personal` or `obsidian-boundary` (per routing) | obsidian-memory + code-analyzer | `project` |

Condensed mirror (~200 lines) linking back to `docs/` for full prose. Skipped with a user-visible notice when the vault MCPs are unavailable.

Nothing else is written to the project tree beyond `docs/`, `.claude/rules/`, `README.md` (fenced region only), `AGENTS.md`, and `CLAUDE.md`.

## Re-running the analyzer

**On every re-run, the skill reconciles three targets against the current codebase:** `docs/`, `.claude/rules/`, and (if `obsidianMirror`) the Obsidian project note. The goal is a *diff-aware update* — not a rewrite from scratch — so the git history of `docs/` stays readable and manual edits survive.

### Reconciliation workflow

1. **Load prior state.**
   - Read every file under `<project>/docs/` (if it exists) and capture each file's `updated` frontmatter and section structure.
   - Read `<project>/.claude/rules/*.md` if present.
   - If `obsidianMirror`, `read_note(Projects/<Project Name>.md)` and `get_frontmatter`.
2. **Detect codebase churn since last run.**
   - Prior `updated` date → compare via `git log --since=<date> --name-only`. List changed files.
   - Cheap sanity checks: `git diff --stat <prior-sha>..HEAD` if the prior `git-sha` frontmatter field is present.
3. **Decide scope per category** based on which files changed:
   - Manifest files changed (`package.json`, `pyproject.toml`, lockfiles, `tsconfig.json`) → re-run **Stack** + **Dependencies** + **Tooling** passes.
   - Config files changed (`.eslintrc*`, `.prettierrc*`, `biome.json`, `.editorconfig`) → re-run **Conventions** + **Tooling**.
   - Test files or test config changed → re-run **Testing**.
   - Source files changed (≥10 files or ≥20% of a directory) → re-run **Architecture** + **Conventions** sampling.
   - CI config changed → re-run **Tooling**.
   - Domain content (READMEs, comments, types named with business terms) changed → re-run **Domain**.
   - Unchanged areas keep their prior content — don't churn what hasn't moved.
4. **Diff old-vs-new per category.** For each re-run category, produce a structured diff:
   - Added items (new deps, new test frameworks, new patterns)
   - Removed items (retired tools, dropped deps)
   - Changed items (version bumps, renamed conventions)
   - Preserved items (still accurate)
5. **Apply changes surgically.**
   - `docs/<file>.md`: replace only the affected sections; preserve manual edits outside code-analyzer-owned headers.
   - **`docs/README.md`:** always refresh the `## At a glance` and `## Quick map` sections when any of stack / dependencies / tooling re-ran, even if the README itself wasn't "changed" — it's the index, so stale values are a regression. Leave the project description paragraph alone unless the source (`package.json#description` etc.) actually changed.
   - **`docs/onboarding.md`:** refresh when `tooling.scripts`, `testing.commands`, or runtime versions in `stack` changed. Re-read `.env.example` every run and sync the env var list.
   - **Project-root `README.md`:** locate the `<!-- code-analyzer:start -->` / `<!-- code-analyzer:end -->` fence and regenerate only the content between them. Refresh whenever stack / tooling / deployment signals changed. If the fence is missing, fall back to the "append at bottom" rule from Phase 4.
   - `.claude/rules/<file>.md`: regenerate the file when its source category changed; skip otherwise.
   - Obsidian note: `read_note` → merge only the affected sections → `write_note` overwrite.
6. **Summarize the diff in `docs/change-log.md`** (and mirror into the Obsidian note's `## Change Log`). Each run produces one entry listing added / removed / changed items per category — this is the collaborator-visible history of the codebase's evolution.
7. **Bump `updated` and `git-sha` frontmatter** on every file written. Leave untouched files alone.
8. If >50 files have changed since the last run, default to **refresh fully** but preserve the `glossary.md` content as a starting point — domain terms rarely become wrong, only incomplete.

### User-facing re-run options

Ask the user up front:
- **Reconcile (default)** — diff-aware update as described above.
- **Refresh fully** — re-run all categories from scratch, overwrite all code-analyzer-owned sections, preserve only manual sections and full Change Log.
- **Docs-only** — reconcile `docs/` and skip `.claude/rules/` + Obsidian mirror.
- **Rules-only** — re-emit `.claude/rules/` from the current `docs/` (or Obsidian note) without re-analyzing source.

## Helper scripts

Use [scripts/inventory.sh](scripts/inventory.sh) to run the Phase 1 file inventory in one shell call. It handles git-tracked vs untracked, respects `.gitignore`, and emits JSON to stdout. Prefer this over hand-rolling `find` commands — it's faster, more consistent across repos, and captures the exact categories Phase 2 needs.

For Phase 2 stack detection, read the manifests listed in the inventory directly with the Read tool — `package.json`, `pyproject.toml`, `go.mod`, etc. No parser script is needed; these files are small and the model reads them accurately.

## Output principles

- **Be specific.** "Uses TypeScript" is useless. "TypeScript 5.4 with `strict: true`, `noUncheckedIndexedAccess: true`, paths aliased via `@/*` to `src/*`" is useful.
- **Cite evidence.** In every section of the project note, each claim should reference at least one file path (and line where applicable) so future verification is cheap.
- **Don't speculate.** If a pattern isn't clearly attested in 3+ places, mark it `confidence: low` or omit it.
- **Prefer observed over declared.** Real code beats config files when they disagree.
- **Generated rules should explain the why.** Don't just say "use 2-space indent" — say "2-space indent (observed in 90% of TS files; matches `.prettierrc`)".
- **Verify every framework/library claim against Context7.** Training data rots. Before writing any statement about a framework, library, SDK, CLI, or cloud-service behavior into `docs/`, `.claude/rules/`, the Obsidian mirror, or the root `README.md`, confirm it against current docs via the Context7 MCP (`mcp__claude_ai_Context7__resolve-library-id` → `mcp__claude_ai_Context7__query-docs`). See the Context7 verification protocol below.

## Context7 verification protocol (MANDATORY)

Every non-trivial technical statement the analyzer emits — about a framework's files, APIs, config keys, defaults, version behavior, conventions, or capabilities — MUST be cross-checked against Context7 before it is written. Memorized APIs are often wrong or stale; repo evidence proves *this project* uses a thing, but Context7 proves the statement *about the thing* is correct.

**When to verify (non-exhaustive):**
- Claims about framework file names, directory conventions, or required files (e.g., `middleware.ts`, `layout.tsx`, `_app.tsx`, `manage.py`).
- Claims about APIs, hooks, decorators, CLI flags, config keys, or their defaults.
- Claims about a framework's version-specific behavior, deprecations, or renames.
- Claims about a library's capabilities, supported runtimes, or integration shape.
- Any rule that tells future agents "X is the way to do Y" in this stack.

**Protocol:**
1. During Phase 2, for every library/framework/runtime detected in the inventory, resolve its Context7 ID once: `mcp__claude_ai_Context7__resolve-library-id(libraryName: "<name>")`. Cache the ID for the session.
2. Before writing any statement about that library, query Context7 with a focused topic: `mcp__claude_ai_Context7__query-docs(context7CompatibleLibraryID: "<id>", topic: "<specific feature>", tokens: 2000–5000)`.
3. If Context7 confirms the statement, write it. If Context7 contradicts memory, **trust Context7**, not training data. If Context7 returns nothing relevant, degrade the claim to `confidence: low` or omit it.
4. Pin the version you verified against in the output (e.g., "Next.js 16.x — `proxy.ts` at project root"). Version-pinning prevents silent rot on future re-runs.

**Canonical example — Next.js 16 `middleware.ts` → `proxy.ts`:**
In Next.js 16, the file formerly named `middleware.ts` was renamed to `proxy.ts`. Agents relying on memory often write "no middleware detected" when `proxy.ts` exists at the project root, or worse, invent `middleware.ts` scaffolding. Before emitting any statement about request interception, routing middleware, or the absence of middleware in a Next.js project, the analyzer MUST query Context7 for the installed Next.js version's middleware docs and reconcile file names against what Context7 describes. The same class of rename/relocation hazard applies across ecosystems (React Router data APIs, Vite config shape, Tailwind v4 `@theme`, Nuxt 3 → 4 directory moves, Django settings modules, Rails autoloader changes, etc.).

**When Context7 is unavailable:** skip the unverifiable claim rather than guess. Record `confidence: low` and add a `TODO: verify via Context7` note in the file. Do not fabricate API or file-name statements from memory.

---

## Related Agents

This skill produces neutral discovery output (`docs/`, `.claude/rules/`, Obsidian
mirror). It does **not** render quality judgments. When the user wants opinions
on top of the discovery, delegate via the Agent tool:

- **`architect`** — when the user wants a forward-looking architectural plan or
  ADR built from the discovery findings. Hand it the `docs/architecture.md` and
  `docs/dependencies.md` files and the user's question.
- **`code-reviewer`** — when the user wants a quality assessment of the
  TypeScript / Next.js / Bun surface. Scope it to specific paths surfaced during
  Phase 2 (e.g., the hot-spot files from the file-size / complexity inventory).
- **`security-reviewer`** — when discovery surfaces auth, input handling,
  secrets, or any OWASP-adjacent code paths. Pass the specific files.
- **`database-reviewer`** — when the inventory finds Postgres/Supabase schemas,
  migrations, or query-heavy modules.

Run agents *after* discovery completes so they reason against finalized docs
rather than partial state. One agent per concern; do not chain into a megareview.
