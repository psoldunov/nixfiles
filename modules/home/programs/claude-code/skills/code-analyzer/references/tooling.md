# Tooling Extraction

Goal: document every tool a contributor needs to run locally — linters, formatters, type checkers, git hooks, CI, scripts — and the exact commands to invoke them.

## What to extract

### Linters
| Tool | Config files |
|---|---|
| ESLint | `.eslintrc*`, `eslint.config.js`, `eslint.config.mjs` |
| Biome | `biome.json`, `biome.jsonc` |
| TSLint | `tslint.json` (legacy, flag for migration) |
| Prettier (formatter but often co-runs) | `.prettierrc*` |
| Ruff | `ruff.toml`, `pyproject.toml [tool.ruff]` |
| Flake8 | `.flake8`, `setup.cfg [flake8]` |
| Pylint | `.pylintrc`, `pyproject.toml [tool.pylint]` |
| Black | `pyproject.toml [tool.black]` |
| golangci-lint | `.golangci.yml`, `.golangci.toml` |
| gofmt / goimports | built-in |
| Clippy | `clippy.toml` |
| RuboCop | `.rubocop.yml` |
| PHPStan / Psalm | `phpstan.neon`, `psalm.xml` |
| Stylelint | `.stylelintrc*` |

### Formatters
- Prettier, Biome, dprint, rustfmt, gofmt, black, ruff format, rubocop -a
- `.editorconfig` applies universally

### Type checkers
- TypeScript: `tsconfig.json` → `tsc --noEmit`
- Python: `mypy.ini`, `pyrightconfig.json`, `pyproject.toml [tool.mypy]`
- Flow: `.flowconfig` (legacy)

### Git hooks
| Tool | Config |
|---|---|
| Husky | `.husky/` |
| lefthook | `lefthook.yml` |
| pre-commit (Python) | `.pre-commit-config.yaml` |
| simple-git-hooks | `package.json "simple-git-hooks"` |
| lint-staged | `package.json "lint-staged"` or `.lintstagedrc*` |

### CI providers
- `.github/workflows/*.yml` → GitHub Actions
- `.gitlab-ci.yml` → GitLab CI
- `.circleci/config.yml` → CircleCI
- `azure-pipelines.yml` → Azure Pipelines
- `Jenkinsfile` → Jenkins
- `bitbucket-pipelines.yml` → Bitbucket Pipelines

### Scripts

Read `package.json → scripts` (or equivalent for other ecosystems: `pyproject.toml [tool.poe.tasks]`, `Makefile`, `justfile`, `Taskfile.yml`). Capture the 5–10 most commonly used ones:
- `dev`, `build`, `start`
- `lint`, `lint:fix`, `format`
- `typecheck`
- `test`, `test:watch`, `test:coverage`
- `db:migrate`, `db:seed`

## How to extract commands

Do NOT invent commands. Read the actual scripts and record verbatim what the team uses. If a `package.json` has `"lint": "eslint . --max-warnings 0"`, record that exact string — the `--max-warnings 0` matters.

## Output

Write prose-first findings to `docs/tooling.md` (always) and mirror a condensed `## Tooling` section into the Obsidian project note (when `obsidianMirror` is on). See [storage.md](storage.md) for both templates and [schemas.md](schemas.md) for the internal findings shape used to keep both targets consistent.

## Heuristics

- If both ESLint and Biome exist, the team is mid-migration — record both, note which one CI actually runs
- If `tsc --noEmit` isn't in CI but `tsconfig.json` exists, type errors aren't enforced — worth flagging
- If `.editorconfig` exists but tools don't honor it (e.g., Prettier overrides), prefer the tool config
- The "commands" section is the most load-bearing part of the tooling note — future Claude sessions will grep for `pnpm lint` or `npm run typecheck` when fixing build errors
