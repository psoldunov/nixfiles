# Domain Extraction

Goal: extract the *business vocabulary* so future code uses the same terms the team already uses. Good domain memory prevents invented synonyms — nothing's worse than Claude calling a `Subscription` a `Plan` because it guessed.

## What counts as a domain term

A term is worth capturing if it meets at least one of:
- Appears as a database table, model, entity, or schema type
- Appears as a URL segment in routes (e.g., `/workspaces/`, `/invoices/`)
- Appears in 3+ unrelated files as a type name, class name, or function prefix
- Is defined in a README, CONTRIBUTING, or ARCHITECTURE doc
- Has a specific, non-generic meaning (skip "User", "Item", "Data" unless the project defines them distinctly)

Skip:
- Framework terms (`Component`, `Handler`, `Middleware`) — those are infrastructure
- Generic CS terms (`Cache`, `Queue`, `Buffer`)
- Acronyms without a clear expansion

## Where to look

Prioritized sources:
1. **Schema files** — Prisma `schema.prisma`, Drizzle `schema.ts`, SQLAlchemy `models.py`, Django `models.py`, Ruby `schema.rb`, GraphQL `.graphql`
2. **Type definitions** — `types.ts`, `domain/*.ts`, `models/*.py`
3. **Routes** — `app/`, `pages/api/`, `routes/`, `handlers/`
4. **Docs** — `README.md`, `docs/`, `ARCHITECTURE.md`
5. **Tests** — test names often describe business concepts more clearly than code

## How to extract

1. Start with schema/model files if present — these are the highest-signal source
2. For each entity found, note the **concrete fields** and any **enum values** — these clarify meaning
3. Search the codebase for the term to confirm it's used consistently (`grep -r "Subscription"`)
4. Write a one-line definition that could fit on an index card
5. Group terms into 2–5 natural categories (e.g., `billing`, `auth`, `workspace`, `integration`)

**Don't invent definitions.** If the codebase doesn't make the meaning clear, either (a) look at tests to see how it's used, or (b) omit the term and note "unclear — ask user".

## Output

Write prose-first findings to `docs/glossary.md` (always, when ≥5 terms) and mirror a condensed `## Domain Glossary` section into the Obsidian project note (when `obsidianMirror` is on). See [storage.md](storage.md) for both templates and [schemas.md](schemas.md) for the internal findings shape.

## Minimum bar

If you find fewer than 5 domain terms, skip both `docs/glossary.md` and `.claude/rules/glossary.md` — the category isn't carrying its weight for this project. Add a one-line note to `docs/README.md` ("Domain vocabulary sparse — rely on code for terminology.") and to the Obsidian note's `## Domain Glossary` section.

## Heuristics

- A term that appears in both `schema.prisma` and `routes/` is almost certainly load-bearing
- If two terms are synonyms in code (e.g., `Account` and `Workspace`), pick the one used more often and note the alias
- Enum values are often the best definitions: `Subscription.status: active|canceled|past_due|trialing` tells you everything you need
- Prefer terms that are *project-specific* over industry-standard. "Invoice" is generic. "CreditNote" in a SaaS context might mean something specific that's worth capturing.
