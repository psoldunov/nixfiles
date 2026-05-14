# Pattern Extraction

Goal: identify the *architectural and design patterns* the team has chosen, so future code respects them.

## What to extract

### Macro-architecture
- **Layout style**: monolith, monorepo, microservices, modular monolith
- **Layering**: clean architecture, hexagonal/ports-and-adapters, MVC, n-tier, flat
- **API style**: REST, GraphQL, tRPC, gRPC, JSON-RPC, server actions
- **Rendering**: SSR, SSG, ISR, CSR, hybrid (RSC + client islands)
- **Data flow**: unidirectional (Redux/Flux), bidirectional (MVVM), reactive (RxJS, signals)
- **Concurrency model**: event loop, goroutines, async/await, threads, actors

### Module organization
- Feature-first (`features/billing/`, `features/auth/`)
- Type-first (`controllers/`, `services/`, `repositories/`)
- Domain-first (`domain/`, `application/`, `infrastructure/`)
- Page-first (`pages/`, `routes/`)
- Hybrid (e.g., `app/` for routes + `lib/features/` for logic)

### Recurring design patterns
Spot patterns by reading 5–15 representative files:
- Repository pattern (DAO classes, `*Repository` files)
- Service layer (`*Service`, business logic separated from controllers)
- Factory functions (`createX`, `makeX`)
- Middleware chains
- Pipeline / functional composition
- Observer / pub-sub
- State machines (XState, finite-state libraries)
- Hooks (custom React hooks → encapsulated stateful logic)
- Server Actions / RPC handlers
- Event-driven (queue consumers, webhook handlers)

### Boundaries
- Where does the code validate input? (handler, middleware, schema parse)
- Where does the code handle errors? (try/catch at handlers, error boundaries, result types)
- Where does the code log? (structured logger, console, framework-managed)
- How is config injected? (env vars, config service, DI container)

## How to sample

Don't read everything. Pick:
1. **One handler/endpoint** (find first match: `app/api/`, `routes/`, `handlers/`, `controllers/`)
2. **One domain/service file** (look for `services/`, `domain/`, `core/`, `business/`)
3. **One data access file** (look for `repositories/`, `db/`, `models/`, `dao/`)
4. **One UI component** if frontend (look for `components/`)
5. **One test file** (just to confirm test patterns)

For each, extract: imports, top-level exports, error-handling style, validation style, naming.

## Output

Write prose-first findings to `docs/architecture.md` (always) and mirror a condensed `## Architecture Notes` section into the Obsidian project note (when `obsidianMirror` is on). See [storage.md](storage.md) for both templates and [schemas.md](schemas.md) for the envelope shape shared across categories. The structured findings object below is the internal schema — hold it in working memory and use it to generate consistent prose across both targets:

```json
{
  "architecture": {
    "layout": "monorepo",
    "layering": "feature-first with thin services",
    "api_style": "next.js server actions + REST routes for webhooks",
    "rendering": "RSC + client islands; ISR for marketing pages",
    "data_flow": "unidirectional via server actions, no global client store",
    "evidence": ["app/dashboard/page.tsx:1-40", "app/actions/billing.ts"]
  },
  "module_organization": {
    "style": "feature-first",
    "root_dirs": ["app/", "lib/features/", "lib/db/", "components/ui/"],
    "rationale": "features colocated under lib/features/<name>/{actions,queries,schema,types}.ts"
  },
  "design_patterns": [
    {
      "name": "schema-first validation at boundaries",
      "evidence": ["lib/features/billing/schema.ts", "app/actions/billing.ts:12"],
      "confidence": "high",
      "description": "All server actions parse input via Zod schemas before business logic"
    },
    {
      "name": "thin server actions delegating to query/mutation modules",
      "evidence": ["app/actions/billing.ts", "lib/features/billing/queries.ts"],
      "confidence": "high"
    }
  ],
  "boundaries": {
    "input_validation": "Zod parse() in server actions",
    "error_handling": "Result-style returns from actions; thrown in queries; caught by ErrorBoundary",
    "logging": "pino with request-scoped child logger",
    "config": "env vars wrapped in lib/env.ts (zod-validated)"
  }
}
```

## Confidence levels

- **high** — observed in 3+ unrelated files, or stated in `ARCHITECTURE.md`/`README.md`
- **medium** — observed in 2 files
- **low** — observed in 1 file or inferred from naming alone (omit unless category is otherwise empty)
