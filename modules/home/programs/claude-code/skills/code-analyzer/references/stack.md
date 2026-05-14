# Stack Extraction

Goal: produce a precise inventory of *what* the project is built with — languages, runtimes, frameworks, package managers, build tools — with versions where they matter.

## What to extract

For each language present:
- **Language + version** (from `engines`, `python_requires`, `go-version`, `rust-version`, etc.)
- **Runtime** (Node 20, Bun, Deno, CPython 3.12, PyPy, JVM 21, etc.)
- **Package manager** (npm, pnpm, yarn classic, yarn berry, bun, pip, poetry, uv, hatch, cargo, go modules, composer, …)
- **Build tool** (Vite, Webpack, Turbopack, esbuild, Rollup, Parcel, Bazel, Make, Gradle, Maven, …)
- **Framework(s)** with version

## Where to look

- `package.json` → `engines`, `packageManager`, `dependencies`, `devDependencies`, `scripts`
- `pyproject.toml` → `[project] requires-python`, `[tool.poetry.dependencies]`, `[tool.uv]`
- `go.mod` → `go 1.X`
- `Cargo.toml` → `[package] rust-version`, `[dependencies]`
- `.tool-versions` (asdf), `.nvmrc`, `.python-version`, `.ruby-version`
- `Dockerfile` → `FROM` lines reveal runtime versions
- `.github/workflows/*.yml` → `actions/setup-node@*` with `node-version`, `setup-python` with `python-version`

## Detection patterns

### Monorepo
- `pnpm-workspace.yaml` → pnpm workspaces
- `package.json` with `workspaces` field → npm/yarn workspaces
- `turbo.json` → Turborepo
- `nx.json` → Nx
- `lerna.json` → Lerna (legacy)
- `Cargo.toml` with `[workspace]` → Cargo workspaces
- `go.work` → Go workspaces

### TypeScript strictness profile
Read `tsconfig.json` and capture:
- `strict`, `noImplicitAny`, `strictNullChecks`, `noUncheckedIndexedAccess`
- `target`, `module`, `moduleResolution`
- `paths` (path aliases — important for understanding imports)
- `jsx` (react, react-jsx, preserve)

### Python project shape
- `pyproject.toml` with `[tool.poetry]` → Poetry
- `pyproject.toml` with `[project]` and no Poetry → PEP 621 (Hatch, Flit, setuptools, uv)
- `requirements*.txt` only → pip-tools or raw pip
- `Pipfile` → Pipenv
- `uv.lock` → uv

## Output

Write prose-first findings to `docs/stack.md` (always) and mirror a condensed `## Stack` section into the Obsidian project note (when `obsidianMirror` is on). See [storage.md](storage.md) for both templates and [schemas.md](schemas.md) for the envelope shape shared across categories. The structured findings object below is the internal schema — hold it in working memory and use it to generate consistent prose across both targets:

```json
{
  "languages": [
    {
      "name": "typescript",
      "version": "5.4.5",
      "version_source": "package.json devDependencies",
      "share": "primary",
      "evidence": ["package.json", "tsconfig.json"]
    },
    {
      "name": "python",
      "version": "3.12",
      "version_source": ".python-version",
      "share": "secondary",
      "evidence": ["pyproject.toml", "scripts/build.py"]
    }
  ],
  "runtime": {
    "node": "20.11.0",
    "node_source": ".nvmrc"
  },
  "package_managers": [
    {"name": "pnpm", "version": "9.1.0", "evidence": "package.json packageManager field"}
  ],
  "build_tools": [
    {"name": "turbopack", "evidence": "next.config.mjs"},
    {"name": "turborepo", "evidence": "turbo.json"}
  ],
  "frameworks": [
    {
      "name": "next.js",
      "version": "15.1.0",
      "router": "app",
      "evidence": ["package.json", "app/layout.tsx"]
    }
  ],
  "monorepo": {
    "kind": "pnpm + turborepo",
    "workspaces": ["apps/*", "packages/*"],
    "evidence": ["pnpm-workspace.yaml", "turbo.json"]
  },
  "typescript": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "paths": {"@/*": ["./src/*"]},
    "evidence": "tsconfig.json"
  }
}
```

## Heuristics

- "primary" language = the one with the most source files; everything else is "secondary"
- If you see both JS and TS files, mark TS as primary unless JS files outnumber TS files >3:1
- If `Dockerfile` and `package.json` disagree on Node version, prefer `Dockerfile` (it's what runs in prod) and note the discrepancy
- If `.nvmrc` exists, that's the canonical local-dev version
