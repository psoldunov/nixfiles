# Style Extraction

Goal: capture concrete, mechanical conventions a future contributor must follow — formatting, naming, imports, file organization.

## What to extract

### Formatting (declared)
Read formatter config files first:
- `.prettierrc*` → indent, quotes, trailing comma, line width, semi
- `.editorconfig` → indent, line ending, charset, trim trailing whitespace
- `biome.json` → formatter section
- `pyproject.toml [tool.black]` or `[tool.ruff.format]`
- `.rustfmt.toml`
- `.clang-format`

### Formatting (observed)
Sample 5–10 source files from different directories. For each, check:
- Indent character (tab vs space) and width (2/4/8)
- Quote style (single vs double)
- Trailing semicolons
- Trailing commas in multi-line literals
- Line length tendency (count chars in 50 random lines)

If declared and observed disagree, **prefer observed** and note the discrepancy. The team's actual habits beat their stale config.

### Naming conventions

For each language, extract:
- **Files**: kebab-case (`user-profile.ts`), camelCase (`userProfile.ts`), snake_case (`user_profile.py`), PascalCase (`UserProfile.tsx`)
- **Variables**: camelCase, snake_case, SCREAMING_SNAKE for constants?
- **Functions**: camelCase, snake_case, PascalCase (rare)
- **Types/Classes**: PascalCase (almost universal — confirm)
- **React components**: PascalCase files vs lowercase files?
- **Test files**: `*.test.ts`, `*.spec.ts`, `__tests__/*.ts`, `*_test.go`, `test_*.py`

### Imports

- Order: external → internal → relative? Or alphabetical? Or grouped by type?
- Path aliases: do files use `@/` or `~/` or relative paths?
- Side-effect imports (CSS, polyfills): where do they live?
- Barrel exports (`index.ts`): used heavily, sparingly, or banned?

### File organization within a feature

For 1–2 features, capture the file shape:
- One file per concern (`actions.ts`, `queries.ts`, `schema.ts`, `types.ts`)?
- One file per entity?
- Colocated tests (`Foo.tsx` + `Foo.test.tsx`) or separate `__tests__/`?
- README per feature?

### Comments and documentation

- JSDoc / TSDoc / docstrings — present, sparse, or ignored?
- Comment style preference (inline `//`, block `/* */`, banner `/** */`)
- TODO/FIXME conventions

## Output

Write prose-first findings to `docs/conventions.md` (always) — note the filename swap: Phase 2 category is `style`, `docs/` file is `conventions.md`, `.claude/rules/` file is `coding-style.md`. Mirror a condensed `## Style` section into the Obsidian project note (when `obsidianMirror` is on). See [storage.md](storage.md) for both templates and [schemas.md](schemas.md) for the envelope shape shared across categories. The structured findings object below is the internal schema — hold it in working memory and use it to generate consistent prose across both targets:

```json
{
  "formatting": {
    "declared": {
      "source": ".prettierrc",
      "indent_size": 2,
      "indent_char": "space",
      "quotes": "single",
      "semi": false,
      "trailing_comma": "all",
      "line_width": 100
    },
    "observed": {
      "indent_size": 2,
      "indent_char": "space",
      "quotes": "single",
      "semi": false,
      "trailing_comma": "all",
      "median_line_length": 78,
      "max_line_length": 142
    },
    "consistency": "high",
    "discrepancies": []
  },
  "naming": {
    "files": {
      "components": "PascalCase.tsx",
      "modules": "kebab-case.ts",
      "tests": "*.test.ts colocated",
      "evidence": ["components/UserProfile.tsx", "lib/billing/calculate-tax.ts"]
    },
    "code": {
      "variables": "camelCase",
      "functions": "camelCase",
      "types": "PascalCase",
      "constants": "SCREAMING_SNAKE_CASE for module-level config; camelCase otherwise",
      "react_components": "PascalCase"
    }
  },
  "imports": {
    "style": "external → @/* aliases → relative",
    "path_alias": "@/*",
    "barrel_exports": "sparingly — only on shared component libraries",
    "evidence": ["app/dashboard/page.tsx:1-12"]
  },
  "feature_layout": {
    "shape": "one folder per feature with {actions,queries,schema,types}.ts",
    "test_location": "colocated *.test.ts",
    "evidence": ["lib/features/billing/", "lib/features/auth/"]
  },
  "comments": {
    "doc_density": "sparse — public API only",
    "style": "TSDoc /** */ on exported functions",
    "todo_format": "// TODO(username):"
  }
}
```

## Sampling protocol

When measuring "observed" formatting:
1. Use `git ls-files` to list source files
2. Pick the 5 largest non-test source files in the primary language
3. Pick 5 random smaller files
4. Read each with the Read tool
5. Tally indent, quotes, semis, line lengths

If 90%+ agree, mark `consistency: high`. If 70–90%, `medium`. Below 70%, `low` and note the variance.
