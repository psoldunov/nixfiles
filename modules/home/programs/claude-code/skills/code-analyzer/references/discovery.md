# Phase 1 — Discovery Reference

Goal: build a fast, structured inventory of the repo *before* reading any source in depth. The output of this phase feeds every later phase, so cast a wide net but stay shallow.

## What to capture

For each item below, record both the file path and (where useful) a one-line excerpt or key fields.

### Manifest files (language detection)

| File | Language / Ecosystem |
|---|---|
| `package.json` | JavaScript / TypeScript / Node |
| `pnpm-workspace.yaml`, `turbo.json`, `nx.json`, `lerna.json` | Monorepo |
| `tsconfig*.json`, `jsconfig.json` | TypeScript / JS config |
| `pyproject.toml`, `setup.py`, `setup.cfg`, `requirements*.txt`, `Pipfile` | Python |
| `go.mod`, `go.sum`, `go.work` | Go |
| `Cargo.toml`, `Cargo.lock` | Rust |
| `Gemfile`, `Gemfile.lock`, `*.gemspec` | Ruby |
| `composer.json`, `composer.lock` | PHP |
| `pom.xml`, `build.gradle`, `build.gradle.kts`, `settings.gradle*` | Java / Kotlin |
| `mix.exs`, `mix.lock` | Elixir |
| `Project.toml`, `Manifest.toml` | Julia |
| `pubspec.yaml`, `pubspec.lock` | Dart / Flutter |
| `Package.swift`, `Podfile`, `*.xcodeproj` | Swift / iOS |
| `*.csproj`, `*.fsproj`, `*.sln`, `Directory.Build.*` | .NET |
| `deno.json`, `deno.jsonc`, `import_map.json` | Deno |
| `bun.lockb` | Bun |

### Framework markers

| File | Framework |
|---|---|
| `next.config.*` | Next.js |
| `nuxt.config.*` | Nuxt |
| `remix.config.*`, `vite.config.*` with `@remix-run` | Remix |
| `svelte.config.*` | Svelte / SvelteKit |
| `astro.config.*` | Astro |
| `angular.json` | Angular |
| `vue.config.*` | Vue CLI |
| `gatsby-config.*` | Gatsby |
| `manage.py`, `wsgi.py`, `asgi.py` + `INSTALLED_APPS` | Django |
| `app.py` + `from flask` | Flask |
| `main.py` + `FastAPI()` | FastAPI |
| `config/application.rb` | Rails |
| `artisan` | Laravel |
| `expo.json`, `app.json` + Expo SDK | Expo / React Native |

### Tooling and quality

- Formatters: `.prettierrc*`, `.editorconfig`, `biome.json`, `dprint.json`, `.rustfmt.toml`, `ruff.toml`, `pyproject.toml [tool.black]`
- Linters: `.eslintrc*`, `eslint.config.*`, `.rubocop.yml`, `.golangci.yml`, `.flake8`, `clippy.toml`, `pyproject.toml [tool.ruff]`
- Type checkers: `tsconfig*.json`, `mypy.ini`, `pyrightconfig.json`
- Test config: `jest.config.*`, `vitest.config.*`, `playwright.config.*`, `cypress.config.*`, `pytest.ini`, `pyproject.toml [tool.pytest]`, `karma.conf.*`
- Git hooks: `.husky/`, `lefthook.yml`, `.pre-commit-config.yaml`, `.git/hooks/`

### CI / CD

- `.github/workflows/*.yml`
- `.gitlab-ci.yml`
- `.circleci/config.yml`
- `azure-pipelines.yml`
- `Jenkinsfile`
- `bitbucket-pipelines.yml`
- `.drone.yml`

### Containers / infra

- `Dockerfile`, `*.dockerfile`
- `docker-compose.*`, `compose.*`
- `kubernetes/`, `k8s/`, `helm/`
- `terraform/`, `*.tf`, `*.tfvars`
- `Pulumi.yaml`
- `serverless.yml`, `sst.config.*`, `vercel.json`, `netlify.toml`, `wrangler.toml`

### Documentation signals

- `README.md`, `README.rst` — read the first 100 lines for project summary
- `CONTRIBUTING.md` — reveals workflow conventions
- `ARCHITECTURE.md`, `docs/` — design documentation
- `CHANGELOG.md` — recent activity signals
- `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.windsurfrules` — existing AI instructions to respect (`AGENTS.md` is the AI-agnostic convention)

### Top-level shape

Capture the first 1–2 levels of directory structure. Look for telltale layouts:
- `apps/` + `packages/` → monorepo (likely Turborepo / Nx / pnpm workspaces)
- `src/`, `lib/`, `internal/`, `pkg/` → conventional layouts
- `domain/`, `application/`, `infrastructure/` → DDD / hexagonal
- `features/`, `modules/` → feature-first organization
- `components/`, `pages/`, `routes/` → frontend conventions
- `cmd/`, `internal/`, `pkg/` → Go-style layout
- `services/` + `gateways/` → microservice or BFF pattern

## Output format

Phase 1 output stays in working memory only — it's raw input to Phase 2 and not a durable finding. The easiest way to produce it is by running the bundled [scripts/inventory.sh](../scripts/inventory.sh), which emits a JSON blob to stdout matching this shape:

```json
{
  "scanned_at": "2026-04-06T12:00:00Z",
  "git_sha": "abc1234",
  "root": "/abs/path",
  "file_count": 1234,
  "manifests": ["package.json", "pnpm-workspace.yaml"],
  "framework_markers": ["next.config.mjs"],
  "tooling": [".prettierrc", "eslint.config.js", "tsconfig.json", "vitest.config.ts"],
  "ci": [".github/workflows/ci.yml"],
  "containers": ["Dockerfile", "compose.yaml"],
  "docs": ["README.md"],
  "top_level_dirs": ["apps", "packages", "scripts", "docs"]
}
```

Hand this object directly to Phase 2 via your conversation state — do NOT persist it as a separate output. Category findings (Phase 2) are the durable artifacts (`docs/`, `.claude/rules/`, optional Obsidian mirror); the inventory is scaffolding.

## What NOT to do in this phase

- Do NOT read source files yet — that's Phase 2
- Do NOT make architectural judgments yet — collect signals first
- Do NOT walk `node_modules/`, `vendor/`, `.venv/`, `dist/`, `build/`, `target/`
- Do NOT exceed 5 minutes wall-clock; this is the cheap pass
