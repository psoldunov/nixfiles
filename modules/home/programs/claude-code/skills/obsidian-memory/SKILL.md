---
name: obsidian-memory
allowed-tools:
  - mcp__obsidian-personal__*
  - mcp__obsidian-boundary__*
user-invocable: false
description: >
  AGENT-AUTO-INVOKED memory system — do NOT wait for the user to ask. The agent MUST silently
  consult this skill at the start of every conversation to check for relevant memories, and at
  the end to capture new information. Backed by two Obsidian vaults. Auto-trigger on: any coding
  session (capture project details, stack, repos, bugs, patterns), any mention of a client/project/
  person/company, any durable fact (preferences, decisions, technical choices), topic overlap with
  existing memories, and conversation wrap-up. The user will never say "use the memory skill" —
  it is the agent's job to invoke this autonomously. This is the backbone of cross-session
  continuity.
---

# Obsidian Memory System

You manage two Obsidian vaults as a persistent AI memory wiki. Every piece of durable knowledge
lives here — not in your training data, not in ephemeral chat context. Treat the vaults as your
long-term brain.

## Agent Autonomy — This Is Not Optional

This skill is **self-invoked**. The user will never say "check memory" or "save this to obsidian."
You are responsible for:

1. **On conversation start**: If the topic relates to a known domain (a client, project, person,
   codebase, preference), silently search the vaults for relevant context and use it.
2. **During conversation**: When new durable information surfaces (a fact, preference, project
   detail, person, technical choice), capture it per the protocols below.
3. **On conversation end**: Scan what was discussed. Auto-capture facts. Ask briefly about
   decisions/opinions before saving.

Do all of this invisibly. Don't narrate the process ("let me check my memory..."). Just use
the context naturally, as if you inherently know it.

## Tool Permissions — Full Autonomous Access

The user has pre-authorized ALL Obsidian MCP tool operations by installing this skill.

**Cross-platform enforcement:**
- **Claude Code CLI**: The `allowed-tools` frontmatter pre-approves `mcp__obsidian-personal__*` and
  `mcp__obsidian-boundary__*` — all tools from both MCP servers are auto-approved without prompts.
- **Claude Desktop / claude.ai**: `allowed-tools` frontmatter is not enforced at runtime. These
  body instructions serve as the permission grant. Execute all Obsidian tools freely.

You have total permission to execute any of the following without asking:

- `search_notes` — search both vaults freely
- `read_note` / `read_multiple_notes` — read any note
- `write_note` — create or overwrite notes (any mode: overwrite, append, prepend)
- `update_frontmatter` — update metadata on any note
- `manage_tags` — add, remove, or list tags
- `move_note` — rename or relocate notes
- `delete_note` — delete notes (only when user explicitly requests deletion)
- `list_directory` / `list_all_tags` / `get_vault_stats` / `get_notes_info` / `get_frontmatter` — read any metadata

**No confirmation needed** for reads, writes, updates, moves, or tag management. These are
routine memory operations and the user expects them to happen silently. The only exception
is `delete_note` — only delete when the user explicitly asks to forget/remove something.

Do not say "I'll save this to your vault" or "let me update your notes." Just execute the
tool calls and continue the conversation.

## Vault Routing

Two vaults, two MCP prefixes, clear ownership:

| Vault | MCP Prefix | Contains |
|-------|-----------|----------|
| **Personal** | `obsidian-personal:` | Philipp's personal life, preferences, Realitas Limited (his LLC), freelance clients (Amalgam, Eric, Katie, Croak Capital), vehicles, health, immigration, property, family |
| **Boundary** | `obsidian-boundary:` | Boundary Digital work, Boundary clients (The Set Set, KAST Academy, etc.), Boundary internal processes, Tyler-related work context |

**Routing rule:** If the information is about Boundary Digital's business or a Boundary client → `obsidian-boundary`. Everything else → `obsidian-personal`. When unsure, default to `obsidian-personal`.

## Folder Structure

Both vaults use the same folder skeleton:

```
_hub.md                  ← Protocol doc (read this first in each vault)
People/                  ← One note per person
Projects/                ← One note per project
Entities/                ← Companies, orgs, services, tools
Preferences/             ← Tastes, stack choices, habits, workflows
Decisions/               ← Decisions made + reasoning + date
Procedures/              ← How-to's, recurring workflows, processes
Context/                 ← Life facts, location, vehicles, health, immigration
Journal/                 ← Timestamped conversation summaries (optional)
```

## Frontmatter Schema

Every note MUST have this frontmatter. Use the `frontmatter` parameter on `write_note` or
`update_frontmatter` to set it — never write YAML manually in the content body.

```yaml
type: person | project | preference | decision | procedure | entity | fact | journal
status: active | archived | outdated
confidence: high | medium | low
source: user-stated | observed | inferred | conversation
created: YYYY-MM-DD
updated: YYYY-MM-DD
related:
  - "[[Note Name]]"
tags:
  - relevant-tag
```

Field guidance:
- `type` → Determines which folder the note lives in. `fact` is the catch-all for Context/ notes.
- `status` → Default to `active`. Set `outdated` when you learn something has changed. Set `archived` for historical reference only.
- `confidence` → `high` for user-stated facts, `medium` for things observed across conversations, `low` for inferences.
- `source` → How this information was obtained. `user-stated` = Philipp said it directly. `observed` = pattern across conversations. `inferred` = logical deduction. `conversation` = captured from a conversation.
- `related` → Obsidian-style wikilinks to other notes. Keep this populated — it's how the graph builds.
- `tags` → Flat, lowercase, kebab-case. Reuse existing tags (check with `list_all_tags` before inventing new ones).

## Core Protocols

### 1. RETRIEVE — Searching for Memories

When the conversation topic might relate to existing memories:

1. **Search both vaults** with `search_notes` using content keywords (not meta-words like "memory" or "note")
2. Also try **frontmatter search** with `searchFrontmatter: true` for type/tag-based lookups
3. If you find relevant notes, `read_note` to load the full content
4. Use the information naturally — don't say "according to my notes" or "I found in my memory"

**When to search:**
- User mentions a person, project, client, or entity by name
- User asks "do you remember..." or references past context
- Topic clearly overlaps with known memory domains (clients, preferences, vehicles, etc.)
- Before writing a new note (to avoid duplicates)

**When NOT to search:**
- Generic questions with no personal angle ("what is a REST API")
- The user is clearly starting a fresh, unrelated topic
- Quick utility tasks (formatting, code snippets) with no memory dimension

### 2. CAPTURE — Writing New Memories

**Auto-capture (do silently, no need to ask):**
- Factual information: names, roles, contact details, dates, locations
- Technical facts: stack choices, account IDs, config details, API keys patterns
- Project facts: URLs, repos, hosting, deployment targets
- Entity facts: company details, addresses, registration numbers
- Preferences stated as facts: "I use Bun", "I prefer plain text emails"

**Ask before capturing:**
- Opinions and subjective preferences: "I think React is better than Vue"
- Decisions with trade-offs: "I'm going to go with Vercel over Hetzner"
- Personal life events that might be sensitive
- Anything where the user might not want it persisted

**Capture protocol:**
1. **Search first** — always check if a note already exists on this topic
2. If exists → **update** the existing note (use `write_note` with mode `overwrite` after reading current content, or use `update_frontmatter` for metadata-only changes)
3. If new → **create** with proper frontmatter, in the correct folder, in the correct vault
4. Keep notes **atomic** — one concept/entity/fact per note. Title should be specific and retrieval-friendly.
5. Update `updated` date in frontmatter whenever modifying a note
6. Add `related` links to connect notes in the graph
7. **Update `_hub.md`** in the same vault — add/rename/archive the bullet under the correct `### Folder` section of `## Current Notes` and bump the hub's `updated` date. See "Hub Maintenance" below. This step is mandatory on every create, rename, archive, or delete.

**Note naming conventions:**
- People: `People/First Last.md`
- Projects: `Projects/Project Name.md`
- Entities: `Entities/Company Name.md`
- Preferences: `Preferences/Topic - Preference.md` (e.g., `Preferences/Dev Stack - Package Manager.md`)
- Decisions: `Decisions/YYYY-MM-DD Decision Title.md`
- Procedures: `Procedures/How to Do Thing.md`
- Context: `Context/Topic.md` (e.g., `Context/Vehicles.md`, `Context/Immigration Status.md`)
- Journal: `Journal/YYYY-MM-DD Summary.md`

### Code Project Memory

Coding sessions are a primary source of durable project knowledge. During any coding conversation,
auto-capture the following to the project note in the correct vault:

**Always capture (auto, no prompt needed):**
- Project name, repo URL, hosting/deployment target
- Stack: framework, runtime, package manager, CMS, database, ORM
- Key file paths and project structure patterns
- Environment setup: env vars needed, services required, build commands
- API integrations: which APIs, auth patterns, endpoint patterns
- Deployment pipeline: where it deploys, CI/CD setup, branch strategy
- Domain/DNS: where DNS lives, domain registrar, CDN

**Capture when they come up in debugging/building:**
- Gotchas and bugs encountered + how they were resolved
- Caching behavior, edge cases, workarounds
- Architecture decisions (why X over Y)
- Third-party service quirks (e.g., "Revolut API has no native subscription engine")
- Performance considerations discovered during development

**Capture significant code changes (auto, after each coding session):**

Any change that would affect how a future agent understands or works with the codebase.
Append to the `## Change Log` section of the project note with a dated entry.

- Feature additions: new functionality, new pages/routes, new API endpoints
- Refactors: restructured modules, renamed key abstractions, moved files
- Migrations: framework version upgrades, dependency swaps, schema changes
- Infrastructure changes: new services, changed hosting, CI/CD pipeline updates
- Breaking changes: removed APIs, changed data models, altered auth flows
- Significant bug fixes: root cause + fix, especially if the bug was subtle or systemic
- Integration changes: added/removed/swapped third-party services or APIs
- Configuration changes: new env vars required, changed build config, new tooling

**What is NOT significant** (don't log these):
- Typo fixes, cosmetic CSS tweaks, copy changes
- Routine dependency bumps with no behavioral change
- Changes the agent just made in the current session that the user hasn't reviewed yet
- WIP/experimental changes the user explicitly says are temporary

**Change log entry format:**
```
### YYYY-MM-DD — Brief Title
What changed and why. Include key files/modules affected.
Impact: what a future agent should know (e.g., "auth now uses middleware instead of per-route checks").
```

**Canonical Project Note Template** (MANDATORY — use this exact skeleton for every `Projects/*.md` note, in both vaults). Do not invent alternative layouts. Fill only the sections you have real data for; keep empty sections as `_TBD_` placeholders so future fills go in the right slot.

```markdown
# {Project Name}

{One-paragraph description: what it is, who it's for, current phase.}

## Summary
- **Status**: active | paused | launched | archived
- **Owner**: {Philipp / Boundary / client name}
- **Client**: {client note link, if any}
- **Started**: YYYY-MM-DD
- **Launched**: YYYY-MM-DD or _TBD_

## Stack
- Framework:
- Runtime:
- Package manager:
- CMS / DB:
- Styling:
- Linter / formatter:
- Testing:

## Repo & Deployment
- Repo:
- Production URL:
- Staging URL:
- Branch strategy:
- CI/CD:
- Hosting:
- DNS / registrar:

## Environment
- Required env vars:
- Local run command:
- Build command:
- Deploy command:

## Architecture Notes
{Key patterns, folder conventions, data flow. Short bullets.}

## API & Integrations
{Which APIs, auth patterns, rate limits, quirks.}

## Known Issues & Gotchas
{Bugs resolved, workarounds, edge cases.}

## Decisions
{Link to `Decisions/*.md` notes. One bullet per decision.}

## People
{Link to `People/*.md` notes involved.}

## Change Log
Reverse-chronological. Most recent first. Each entry uses the format below.

### YYYY-MM-DD — {Brief Title}
What changed and why. Files/modules affected.
Impact: {what a future agent should know}.
```

When updating project notes during a coding session, read-then-overwrite (or `append` to the Change Log) to preserve existing content. Always bump `updated` in frontmatter. Never drop sections — if empty, leave the heading with `_TBD_`.

### 3. MAINTAIN — Keeping Memories Fresh

- When you learn something has changed, update the note and bump `updated`
- If a fact is contradicted, set old note to `status: outdated` and create a new one (or update in place if it's a simple correction)
- When a note references other notes that don't exist yet, create stubs
- Periodically check `updated` dates — anything older than 6 months with `confidence: low` should be treated with skepticism

### 4. FORGET — Removing Memories

Only delete notes when the user explicitly asks. Use `delete_note` with the confirmation parameter. For soft-deletion, set `status: archived` instead.

## Conversation Wrap-Up

At the end of substantive conversations (not quick Q&As), silently scan for:
- New facts that emerged → auto-capture without announcing
- Decisions that were made → ask briefly, then capture
- Changed facts → update existing notes
- New people/projects/entities mentioned → create notes
- Code project details learned → update the project note

Keep it brief if you need to ask: "Want me to save that decision about [X] to memory?"
Never say "I'm now updating my memory" or "let me save this to Obsidian." Just do it.

## Hub Maintenance — MANDATORY

Each vault has `_hub.md` at root. It is the **index** of the vault and MUST be kept in sync. Treat it as a first-class artifact, not a static doc.

### Read
At the start of the first conversation in a session touching that vault, `read_note('_hub.md')` for orientation.

### Update (REQUIRED on every capture)
Any time you **create**, **rename**, **archive**, or **delete** a note, you MUST also update `_hub.md` in the same vault in the same turn. No exceptions. If you forget, the hub drifts and future agents lose the index.

**What to update:**
- **Create** → add a bullet under the correct `### {Folder}` section of `## Current Notes`, format: `- [[Note Title]] — one-line hook`
- **Rename** → update the wikilink text
- **Archive** (`status: archived`) → move bullet into a `### Archived` sub-section at the bottom of `## Current Notes`
- **Delete** → remove the bullet entirely
- Always bump `updated: YYYY-MM-DD` in the hub's frontmatter

### Canonical Hub Template

Both vaults MUST follow this exact skeleton. Only `# Title`, `## Scope` body, and `## Current Notes` bullets differ between vaults.

```markdown
---
type: system
status: active
updated: YYYY-MM-DD
---

# {Vault Name} — AI Memory Hub

{One-paragraph scope statement.}

## Scope
- {Bullet list of what belongs in this vault}

## Folder Index

| Folder | Contains |
|--------|----------|
| `People/` | One note per person |
| `Projects/` | One note per project |
| `Entities/` | Companies, orgs, services, tools |
| `Preferences/` | Tastes, stack choices, habits, workflows |
| `Decisions/` | Decisions + reasoning + date |
| `Procedures/` | How-to's, recurring workflows |
| `Context/` | Life/business facts |
| `Journal/` | Timestamped conversation summaries |

## Current Notes

### People
- [[Name]] — role, relationship

### Projects
- [[Project]] — one-line hook (status, stack)

### Entities
- [[Entity]] — one-line hook

### Preferences
- [[Topic - Preference]] — one-line hook

### Decisions
- [[YYYY-MM-DD Decision Title]] — one-line hook

### Procedures
- [[How to X]] — one-line hook

### Context
- [[Topic]] — one-line hook

### Journal
- [[YYYY-MM-DD Summary]] — one-line hook

### Archived
- [[Old Note]] — reason archived

## Protocol
- Every note has full frontmatter (see SKILL.md)
- Notes are atomic — one concept per note
- Search before writing to avoid duplicates
- Facts auto-captured; opinions/decisions confirmed
- `related` links build the graph — keep populated
- This hub is updated on every create/rename/archive/delete
```

### Folder Skeleton Enforcement

Both vaults use the **same 8-folder skeleton**: `People/ Projects/ Entities/ Preferences/ Decisions/ Procedures/ Context/ Journal/`. If you need to write a note of a type whose folder doesn't exist yet in that vault, create the folder implicitly via the first `write_note` to that path — do not re-route the note to a different folder. The `Folder Index` table in `_hub.md` lists all eight regardless of whether they currently contain notes.

## Tool Reference

Read `references/tools.md` for the complete list of available Obsidian MCP tools and their parameters.