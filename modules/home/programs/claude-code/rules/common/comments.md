# Comments and Doc Comments

Code explains itself through names and structure. The only prose a code file
carries is a doc comment on a declaration. This rule replaces ponytail's
"comment only the why" line and any harness default that allows explanatory
comments.

## Where it applies

Every code file you write or edit: TypeScript, JavaScript, Python, Rust, Go,
Swift, shell and the rest.

Exempt:

- Nix files, scripts embedded in `.nix` strings included
- Config and data files: YAML, TOML, JSON, CSS, SQL, Dockerfile
- Generated code and vendored third-party sources

A repo's own written comment convention wins: its `CLAUDE.md` or `AGENTS.md`,
or a lint rule that contradicts this one.

## Doc comments

Every named function carries a doc comment stating its purpose, each input
and its output. That covers functions, methods, React components, private
helpers, nested named functions and test helpers. Anonymous inline callbacks
(`.map((user) => user.id)`) and test cases (`it('…')`, whose name is the doc)
carry none.

Any other declaration may carry one: a constant, type, field or module.

Write each in the language's idiom:

| Language | Form |
|---|---|
| TypeScript | TSDoc: `@param name - …` per parameter, `@returns` unless `void`, `@throws` when it throws on purpose. No `{type}`: the signature has it. Module: `/** @file … */`. |
| JavaScript | JSDoc, with `{type}` on `@param` and `@returns`. |
| Python | Google-style docstring: `Args:`, `Returns:`, `Raises:`. Module: a module docstring. |
| Rust | `///` summary, inputs in prose, `# Errors` and `# Panics` when they apply. Module: `//!`. |
| Go | A doc comment that starts with the function's name. |
| Shell | A `#` block directly above the function: purpose, arguments, output, exit codes. |
| Other | The language's standard doc-comment form. |

The why lives here too. A workaround, an upstream bug or a magic number goes
in the doc comment's remarks (`@remarks` in TSDoc, a paragraph in a
docstring), or becomes a named constant whose doc comment says it:

```ts
/** The upstream API rejects a request with more than 100 records. */
const MAX_BATCH_SIZE = 100

/**
 * Splits records into batches the upstream API accepts.
 *
 * @param records - Records to send, in order.
 * @returns Batches of at most `MAX_BATCH_SIZE` records, order preserved.
 */
function toBatches<T>(records: readonly T[]): T[][] {
  return Array.from({ length: Math.ceil(records.length / MAX_BATCH_SIZE) }, (_, index) =>
    records.slice(index * MAX_BATCH_SIZE, (index + 1) * MAX_BATCH_SIZE),
  )
}
```

## Inside the code

Function bodies and module-level code hold only code, plus these one-line
markers:

- **Tool directives**: `@ts-expect-error`, `eslint-disable-next-line`,
  `biome-ignore`, `# noqa`, `# type: ignore`, shebangs, Rust `// SAFETY:`.
  Put the reason after the directive where the tool accepts one:
  `// @ts-expect-error upstream types lag behind v3`.
- **Debt markers**: `// shortcut: <limit>, <when to upgrade>`, on the line
  that takes the shortcut, where `/ponytail-debt` finds it.

What a comment would have said goes elsewhere:

- What a block does → extract it into a named function with its own doc comment.
- Why it does it → the doc comment's remarks, or a named constant.
- Unfinished work → a `shortcut:` marker or an issue. TODO and FIXME stay out.
- Old code → delete it; git keeps it.

## Code you touch

Every function you write or edit leaves compliant: move its comments into its
doc comment or delete them, and add the doc comment when it has none. Leave
untouched code as it is; sweep a whole file or repo only when asked.

## Review

A reviewer reports a violation of this rule as **blocking**, citing this file.
