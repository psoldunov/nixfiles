# Testing Extraction

Goal: capture how the project tests itself so future code follows the same conventions.

## What to extract

- **Frameworks in use** — unit, integration, e2e tiers may differ
- **Test file locations** — colocated, `__tests__/`, `test/`, `tests/`, `spec/`
- **Naming pattern** — `*.test.ts`, `*.spec.ts`, `test_*.py`, `*_test.go`
- **Commands** — how does the user actually run tests? Read `package.json scripts`, `Makefile`, `Taskfile.yml`, `justfile`
- **Coverage** — tool (c8, v8, nyc, coverage.py, go cover), threshold, current percentage if reported
- **CI integration** — which workflow runs tests, what gates exist
- **Mocking conventions** — what's faked, what's real (e.g., MSW for HTTP, testcontainers for DB)
- **Fixtures location** — `test/fixtures/`, `__fixtures__/`, `testdata/`

## Detection cheat sheet

| Framework | Primary signals |
|---|---|
| jest | `jest.config.*`, `jest` in `package.json`, `*.test.ts` with `describe/it` |
| vitest | `vitest.config.*`, `vitest` in deps, `import from 'vitest'` |
| mocha | `.mocharc*`, `mocha` in deps |
| node:test | `import from 'node:test'`, no other framework |
| bun test | `bun test` in scripts, `bun:test` imports |
| playwright | `playwright.config.*`, `@playwright/test` |
| cypress | `cypress.config.*`, `cypress/` |
| pytest | `pytest.ini`, `pyproject.toml [tool.pytest]`, `conftest.py` |
| unittest | `test_*.py` with `import unittest` |
| go test | `*_test.go` files (built in) |
| cargo test | `#[test]` or `#[cfg(test)]` in Rust files |
| rspec | `spec/`, `Gemfile` with `rspec` |
| phpunit | `phpunit.xml`, `tests/` with `extends TestCase` |

## How to read tests (sampling)

Read 2–3 representative test files from different tiers (unit, integration, e2e if present). For each:
- Imports (what framework? what matchers? what mocking library?)
- Setup/teardown style (beforeEach, fixtures, `test.setup.ts`)
- Assertion style (expect, assert, should)
- Naming (what does a test title look like?)

This reveals both the framework *and* the team's unspoken conventions (e.g., "one assertion per test" vs "grouped assertions", "arrange-act-assert vs given-when-then").

## Output

Write prose-first findings to `docs/testing.md` (always) and mirror a condensed `## Testing` section into the Obsidian project note (when `obsidianMirror` is on). See [storage.md](storage.md) for both templates and [schemas.md](schemas.md) for the internal findings shape used to keep both targets consistent.

## Heuristics

- If `vitest.config.ts` and `jest.config.js` both exist, the team is mid-migration — record both, note it
- If only `describe/it` patterns are used but no framework is declared, check what's actually installed (`npm ls` or `package.json`)
- Coverage threshold matters: a project with 80% gate signals strong test culture; no gate signals "tests exist, but aren't enforced"
- Presence of `testdata/`, `fixtures/`, or `__snapshots__/` tells you how they handle deterministic data
- If there are *zero* tests, still write the note — that's a finding: "No automated tests present"
