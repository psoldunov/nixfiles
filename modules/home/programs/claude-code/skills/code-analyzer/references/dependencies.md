# Dependencies Extraction

Goal: surface the *notable* dependencies — the ones that shape how code is written — not an exhaustive list of every transitive package.

## What counts as notable

A dependency is worth recording if it answers one of these:
- "How does this project handle X?" (where X is auth, state, data fetching, validation, ORM, routing, styling, etc.)
- "What conventions does this dependency impose?" (e.g., Zod imposes schema-first validation; Prisma imposes a generated client)
- "Would future code in this project need to follow patterns from this lib?"

Skip:
- Tiny utilities (lodash, classnames, clsx, debug)
- Polyfills (core-js)
- Build-only deps already covered in stack.json (esbuild, swc)
- Transitive deps unless they're the *interface* (e.g., `react` is direct even when pulled in via `next`)

## Categorize

Group findings into these buckets — only emit non-empty buckets:

| Bucket | Examples |
|---|---|
| `data` | prisma, drizzle, kysely, sqlalchemy, typeorm, mongoose, supabase-js |
| `auth` | next-auth, auth.js, lucia, clerk, supabase-auth, passport, devise |
| `validation` | zod, yup, valibot, joi, pydantic, marshmallow |
| `state` | zustand, jotai, redux-toolkit, mobx, pinia, vuex, xstate |
| `data_fetching` | tanstack-query, swr, apollo, urql, trpc |
| `ui` | react, vue, svelte, solid, lit, angular |
| `styling` | tailwindcss, css-modules, emotion, styled-components, vanilla-extract, stitches |
| `components` | shadcn-ui, radix-ui, headlessui, mantine, mui, chakra, antd, ariakit |
| `forms` | react-hook-form, formik, conform, tanstack-form |
| `routing` | react-router, tanstack-router, next/navigation, vue-router |
| `testing` | vitest, jest, playwright, cypress, pytest, go-test, rspec |
| `http` | axios, ky, undici, requests, httpx, reqwest |
| `dates` | date-fns, dayjs, luxon, temporal-polyfill, arrow |
| `i18n` | next-intl, react-intl, i18next, vue-i18n |
| `observability` | sentry, datadog, opentelemetry, pino, winston, structlog |
| `ai` | ai-sdk, openai, anthropic-sdk, langchain, llamaindex |
| `infrastructure` | aws-sdk, gcp-cloud, azure-sdk, vercel, netlify-cli |

## Where to look

- `package.json` → `dependencies`, `devDependencies`, `peerDependencies`
- `pyproject.toml` → `[tool.poetry.dependencies]` or `[project] dependencies`
- `requirements*.txt`
- `go.mod` → `require`
- `Cargo.toml` → `[dependencies]`, `[dev-dependencies]`
- `Gemfile`
- `composer.json` → `require`, `require-dev`

## Output

Write prose-first findings to `docs/dependencies.md` (always) and mirror a condensed `## Dependencies` section into the Obsidian project note (when `obsidianMirror` is on). See [storage.md](storage.md) for both templates and [schemas.md](schemas.md) for the envelope shape shared across categories. The structured findings object below is the internal schema — hold it in working memory and use it to generate consistent prose across both targets:

```json
{
  "ecosystem_count": 1,
  "buckets": {
    "data": [
      {"name": "drizzle-orm", "version": "0.30.0", "type": "prod", "notable_because": "ORM — defines data layer conventions"}
    ],
    "auth": [
      {"name": "@clerk/nextjs", "version": "5.0.0", "type": "prod", "notable_because": "Auth provider — middleware patterns"}
    ],
    "validation": [
      {"name": "zod", "version": "3.23.0", "type": "prod", "notable_because": "Schema-first validation; expect parse() at boundaries"}
    ]
  },
  "total_direct_dependencies": 47,
  "deprecated_or_legacy": [
    {"name": "moment", "reason": "deprecated; suggest migration to date-fns or temporal"}
  ]
}
```

## Heuristics

- If `react` and `next` both appear, only call out `next` (it implies react)
- If a project uses `prisma`, expect schema-first DB patterns and generated clients
- If you see `@vercel/ai`, look for `ai-sdk` patterns specifically (streaming, tool calling)
- If both `eslint` and `biome` exist, the team is mid-migration — note this
- Cap each bucket at 10 entries; if more, list the most-imported ones first
