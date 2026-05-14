# Finding Schemas

Every category note contains a fenced JSON block matching one of the schemas below. These schemas are the programmatic contract — keep them stable.

All schemas share this envelope:

```json
{
  "category": "<stack|dependencies|patterns|style|testing|tooling|domain>",
  "confidence": "<high|medium|low>",
  "evidence_count": 12,
  "last_analyzed": "2026-04-06T12:00:00Z",
  "git_sha": "abc1234",
  "findings": { /* category-specific shape */ }
}
```

## Stack (`category: "stack"`)

See [stack.md](stack.md) for the full `findings` shape. Core fields:

```json
{
  "languages": [{"name": "typescript", "version": "5.4.5", "share": "primary", "evidence": ["package.json"]}],
  "runtime": {"node": "20.11.0", "node_source": ".nvmrc"},
  "package_managers": [{"name": "pnpm", "version": "9.1.0"}],
  "build_tools": [{"name": "turbopack"}],
  "frameworks": [{"name": "next.js", "version": "15.1.0", "router": "app"}],
  "monorepo": {"kind": "pnpm + turborepo", "workspaces": ["apps/*", "packages/*"]},
  "typescript": {"strict": true, "paths": {"@/*": ["./src/*"]}}
}
```

## Dependencies (`category: "dependencies"`)

```json
{
  "ecosystem_count": 1,
  "buckets": {
    "data": [{"name": "drizzle-orm", "version": "0.30.0", "type": "prod", "notable_because": "..."}],
    "auth": [...],
    "validation": [...]
  },
  "total_direct_dependencies": 47,
  "deprecated_or_legacy": [{"name": "moment", "reason": "..."}]
}
```

## Patterns (`category: "patterns"`)

```json
{
  "architecture": {
    "layout": "monorepo",
    "layering": "feature-first with thin services",
    "api_style": "server actions + REST webhooks",
    "rendering": "RSC + client islands",
    "data_flow": "unidirectional",
    "evidence": ["app/dashboard/page.tsx:1-40"]
  },
  "module_organization": {
    "style": "feature-first",
    "root_dirs": ["app/", "lib/features/"],
    "rationale": "..."
  },
  "design_patterns": [
    {"name": "schema-first validation", "evidence": [...], "confidence": "high", "description": "..."}
  ],
  "boundaries": {
    "input_validation": "Zod parse in server actions",
    "error_handling": "Result-style returns",
    "logging": "pino",
    "config": "env vars via lib/env.ts"
  }
}
```

## Style (`category: "style"`)

```json
{
  "formatting": {
    "declared": {"source": ".prettierrc", "indent_size": 2, "quotes": "single", "semi": false},
    "observed": {"indent_size": 2, "quotes": "single", "median_line_length": 78},
    "consistency": "high",
    "discrepancies": []
  },
  "naming": {
    "files": {"components": "PascalCase.tsx", "modules": "kebab-case.ts"},
    "code": {"variables": "camelCase", "types": "PascalCase"}
  },
  "imports": {"style": "external → @/* aliases → relative", "path_alias": "@/*"},
  "feature_layout": {"shape": "actions/queries/schema/types per folder", "test_location": "colocated"},
  "comments": {"doc_density": "sparse", "style": "TSDoc"}
}
```

## Testing (`category: "testing"`)

```json
{
  "frameworks": [{"name": "vitest", "version": "1.6.0", "scope": "unit+integration"}],
  "test_locations": ["colocated *.test.ts", "e2e/"],
  "commands": {
    "unit": "pnpm test",
    "watch": "pnpm test:watch",
    "e2e": "pnpm test:e2e",
    "coverage": "pnpm test:coverage"
  },
  "coverage": {"tool": "v8", "threshold": 80, "current": 72, "config": "vitest.config.ts"},
  "ci_integration": [".github/workflows/test.yml"],
  "mocking_style": "vi.mock for modules, MSW for HTTP",
  "fixtures_location": "test/fixtures/"
}
```

## Tooling (`category: "tooling"`)

```json
{
  "linters": [{"name": "eslint", "config": "eslint.config.js", "command": "pnpm lint"}],
  "formatters": [{"name": "prettier", "config": ".prettierrc", "command": "pnpm format"}],
  "type_checkers": [{"name": "tsc", "command": "pnpm typecheck"}],
  "git_hooks": {"manager": "husky + lint-staged", "config": ".husky/", "runs": ["lint-staged", "tsc --noEmit"]},
  "ci": {"provider": "github-actions", "workflows": [".github/workflows/ci.yml"], "gates": ["lint", "typecheck", "test"]},
  "scripts": {
    "dev": "pnpm dev",
    "build": "pnpm build",
    "start": "pnpm start"
  },
  "containers": {"dockerfile": "Dockerfile", "compose": "compose.yaml"}
}
```

## Domain (`category: "domain"`)

```json
{
  "terms": [
    {
      "term": "Subscription",
      "definition": "A recurring billing agreement; modeled as db.subscription with status enum",
      "evidence": ["lib/features/billing/schema.ts:20", "app/api/webhooks/stripe/route.ts:45"],
      "category": "billing"
    },
    {
      "term": "Workspace",
      "definition": "Multi-tenant grouping; every user belongs to at least one",
      "evidence": ["lib/features/workspace/", "lib/auth/middleware.ts:12"],
      "category": "core"
    }
  ],
  "term_count": 23,
  "top_categories": ["billing", "auth", "workspace", "integration"]
}
```

## Schema evolution

If the skill needs new fields in the future:
- **Add** new optional fields freely
- **Remove** fields only by bumping a `schema_version` in the envelope and updating the viewer
- **Rename** fields only via `consolidate` + rewrite, not in-place
