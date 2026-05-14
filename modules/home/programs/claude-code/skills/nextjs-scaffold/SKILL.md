---
name: nextjs-scaffold
description: >
  Scaffold a new Next.js web application using only official CLI commands — never
  hand-generate files. Wires `src/` layout, Tailwind, Biome (replaces ESLint), and
  initializes shadcn/ui. Use this skill whenever the user wants to "create a Next.js
  app", "scaffold a Next.js project", "start a new Next.js project", "bootstrap
  Next.js with Tailwind and shadcn", or any variant of bootstrapping a new web app
  with the Next.js stack. Trigger on phrases like "new next app", "spin up a Next.js
  project", "set up a Next.js repo", "init next.js with shadcn", "create-next-app
  with biome". Do NOT trigger when the user wants to modify an existing Next.js
  project — this is greenfield scaffolding only.
---

# Next.js Scaffold Skill

Bootstraps a fresh Next.js web application by orchestrating **official CLI tools only**.
No hand-rolled boilerplate, no template copy-paste, no manual file creation during
scaffolding.

---

## Hard rules

1. **Official commands only.** All project structure comes from `create-next-app`,
   `bunx shadcn`, and package manager commands. Never `Write`/`Edit` files during
   scaffolding. The only exception: deleting files that the official tools generated
   but the chosen stack doesn't need (e.g. ESLint configs when Biome is selected).
2. **Bun is the package manager and runtime.** Use `bun create`, `bunx`, `bun add`.
3. **User adds Biome config later.** Do NOT write a `biome.json`. Install Biome as a
   dev dependency and run its init only if the user explicitly asks; otherwise leave
   config to the user.
4. **Stop on error.** If any command fails, surface the error verbatim and ask the
   user how to proceed. Do not attempt to "patch" failures by writing files.

---

## Process

### Step 1: Gather minimal inputs

Ask via `AskUserQuestion` only what you can't infer. Required inputs:

- **Project name** — directory name (kebab-case). If user already provided one in
  the prompt, use it without asking.
- **Target directory** — defaults to `$PWD/<project-name>`. Confirm only if ambiguous.

Do NOT ask about stack choices that are fixed by this skill:
- `src/` directory: YES
- TypeScript: YES
- Tailwind: YES
- App Router: YES
- ESLint: NO (replaced by Biome)
- Turbopack: YES
- Import alias: `@/*`
- Package manager: `bun`

### Step 2: Verify environment

Run in parallel:
```bash
bun --version
node --version
```

If `bun` missing, stop and tell the user to install it.

### Step 3: Scaffold with `create-next-app`

Run the official command non-interactively. Verify the flag list first if uncertain:

```bash
bun create next-app@latest --help
```

Then scaffold:

```bash
bun create next-app@latest <project-name> \
  --ts \
  --tailwind \
  --app \
  --src-dir \
  --turbopack \
  --use-bun \
  --no-eslint \
  --import-alias "@/*" \
  --no-git \
  --yes
```

Notes:
- Use `--no-eslint` (or `--eslint=false` depending on CLI version) so Biome can take
  over without conflict.
- `--no-git` keeps git init under the user's control. If user wants a repo, run
  `git init` after.
- If a flag name changed in a newer CLI version, re-check `--help` and adapt.

### Step 4: Add Biome

`cd` into the new project, then:

```bash
bun add -D -E @biomejs/biome
```

Do **not** generate `biome.json`. The user will add their own config.

Remove any ESLint artifacts `create-next-app` may have left despite `--no-eslint`
(only delete files that exist):

```bash
rm -f eslint.config.mjs eslint.config.js .eslintrc.json .eslintrc.js
```

Strip `lint` script and ESLint deps from `package.json` if present — use `bun pm`
or `npm pkg delete scripts.lint` to keep edits official rather than hand-editing
JSON.

```bash
npm pkg delete scripts.lint
bun remove eslint eslint-config-next 2>/dev/null || true
```

Add Biome scripts via the official pkg CLI:

```bash
npm pkg set scripts.lint="biome check ."
npm pkg set scripts.format="biome format --write ."
```

### Step 5: Initialize shadcn/ui

Run the official initializer non-interactively:

```bash
bunx --bun shadcn@latest init --yes
```

If the CLI prompts, accept defaults that match this skill's stack (TypeScript, Tailwind,
`@/*` alias, `src/` layout). The `--yes` flag should bypass prompts on recent versions;
if not, pass explicit flags (`--base-color`, `--css-variables`, etc.) per `shadcn init --help`.

### Step 6: Report

Print a short summary to the user:
- Project path
- Stack: Next.js (App Router) + TS + Tailwind + Biome + shadcn/ui, `src/`, Bun
- Next steps for the user:
  1. Drop in their `biome.json`
  2. `cd <project>` and `bun dev`
  3. Add shadcn components: `bunx --bun shadcn@latest add button`

Do not run `bun dev` automatically. Do not commit. Do not create a remote.

---

## Failure handling

- **`create-next-app` flag rejected:** rerun `--help`, adapt flags, retry once. If it
  still fails, stop and show the error.
- **`shadcn init` errors:** stop and show the error verbatim. Do not write a fallback
  `components.json` by hand.
- **Network/registry errors:** stop. Tell the user.

---

## Out of scope

- Database setup (Drizzle, Prisma, etc.)
- Auth (NextAuth, Clerk, etc.)
- Deployment config (Vercel, Docker)
- CI workflows
- Writing `biome.json` or other config files

These can be added later by other skills or by the user.
