---
name: git-stage-commit
description: Stage changed files and generate a Conventional Commits message from the diff, then commit after user confirmation. Use whenever the user asks to "commit my changes", "stage and commit", "make a commit", "wrap this up in a commit", "git add and commit", "write a commit for what I just did", or any variant where they want their working-tree changes turned into one well-formed commit. Also trigger when the user says "/commit" or invokes a commit shortcut. Do NOT push — this skill stops at the commit. Selective staging: skips secrets, env files, and large binaries unless the user explicitly opts in.
---

# git-stage-commit

Turn the current working tree into one clean Conventional Commits commit. Stage the right files, draft the message from the actual diff, show the user, commit on confirm.

## Why this exists

Writing good commit messages is friction. The model has the diff right there — it can produce a tighter, more accurate subject than the user typing one in a hurry. But a skill that auto-commits without showing the message first is dangerous (typos get baked into history, secrets sneak in). So the contract is: **skill drafts, user confirms, skill commits**. No push.

## Workflow

1. **Inspect repo state** — run these in parallel:
   - `git status --short` (untracked + modified)
   - `git diff` (unstaged changes)
   - `git diff --cached` (anything already staged)
   - `git log -5 --oneline` (style of recent commits in this repo)

2. **Decide what to stage** — see "Staging rules" below. Show the user the staging plan as a bullet list before running `git add`. Format:
   ```
   Will stage:
   - src/auth/login.ts
   - src/auth/session.ts

   Will SKIP (looks sensitive / not source):
   - .env.local       (env file)
   - dist/bundle.js   (build artifact)
   ```
   If everything is clean (skip list empty), just say "Staging all 4 changed files." and move on.

3. **Stage** — `git add <file1> <file2> ...` with explicit paths. Never `git add -A` or `git add .` — those sweep up surprises.

4. **Re-read staged diff** — `git diff --cached`. The message must describe what is staged, not what is in the working tree.

5. **Detect split-worthy commits** — if the staged diff spans clearly unrelated concerns (e.g. an auth bug fix AND a docs update AND a refactor in an unrelated module), stop and ask: "These changes look unrelated — split into separate commits?" with a proposed grouping. If user says "one commit", proceed.

6. **Draft the message** — see "Message format". Show the user the full message in a fenced block.

7. **Ask for confirmation** — exact wording: "Commit with this message? (yes / edit / cancel)". Wait for response.
   - `yes` → run the commit
   - `edit` → ask what to change, redraft, ask again
   - `cancel` → stop, leave files staged

8. **Commit** — use a HEREDOC so multi-line bodies format correctly:
   ```bash
   git commit -m "$(cat <<'EOF'
   feat(auth): add JWT refresh token rotation

   Tokens now rotate on every refresh to limit blast radius of
   leaked refresh tokens. Old refresh tokens are revoked server-side.
   EOF
   )"
   ```

9. **Report** — single line: commit hash + subject. Done. Do NOT push.

## Staging rules

Stage by default:
- Source files (any language)
- Config files that are clearly project config (`tsconfig.json`, `pyproject.toml`, `Cargo.toml`, etc.)
- Tests
- Docs (`*.md`, `docs/`)
- Lockfiles (`package-lock.json`, `pnpm-lock.yaml`, `Cargo.lock`, `uv.lock`) when accompanying a dependency change

**Skip and warn** (require explicit user opt-in to include):
- `.env`, `.env.*`, `*.pem`, `*.key`, `id_rsa*`, `credentials.json`, `secrets.*`
- Files matching common secret patterns (anything with `SECRET`, `TOKEN`, `PASSWORD`, `API_KEY` in the name unless it's a clearly-public sample like `.env.example`)
- Build outputs (`dist/`, `build/`, `out/`, `.next/`, `target/`) — these usually shouldn't be tracked; if they're showing up something is wrong with `.gitignore`
- Large binaries (>5MB) — flag and ask
- IDE/OS junk (`.DS_Store`, `Thumbs.db`, `.idea/`, `.vscode/` unless project tracks them)

If user explicitly says "include the .env" or similar, stage it but warn one more time about secret exposure before committing.

## Message format

**Subject line:** `<type>(<scope>): <description>` — Conventional Commits.

- `<type>`: one of `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`, `style`, `build`
- `<scope>`: optional, lowercase, the area touched (`auth`, `api`, `parser`). Skip if the change is repo-wide or scope adds no info.
- `<description>`: imperative mood, lowercase first letter, no trailing period, ≤50 chars total subject (including type+scope).

**Body:** only when the "why" isn't obvious from the subject + diff. If you'd write something like "this changes the X to Y" — skip it, the diff already says that. Body is for context the diff can't show: the bug it fixes, the constraint it satisfies, the tradeoff being made. Wrap at ~72 chars.

**No footer** unless the user has set up trailers (Signed-off-by, etc.) — check recent `git log` to see if the repo uses them.

### Picking the type

Default decision tree:
- New user-facing capability or API → `feat`
- Restoring broken behavior → `fix`
- Internal restructuring with no behavior change → `refactor`
- Speed/memory improvement → `perf`
- Tests only → `test`
- Docs only → `docs`
- Tooling, deps, build config, CI → `chore` or `build` or `ci` (most repos collapse these into `chore` — match what `git log` shows)
- Pure formatting → `style`

If the diff genuinely mixes types (e.g. a feature + its tests + a doc update for it), use the dominant type — `feat` covers its own tests and docs. A multi-type label like `feat+test:` is not Conventional Commits.

### Examples

**Example 1 — small fix:**
```
fix(auth): use <= for token expiry comparison

Tokens were expiring one second early because the boundary check
was strict. Affects every authenticated request near expiry.
```

**Example 2 — feature, body unnecessary:**
```
feat(api): add /health endpoint
```

**Example 3 — refactor:**
```
refactor(parser): extract token stream into separate module
```

**Example 4 — chore:**
```
chore: bump typescript to 5.4.2
```

## Repo style adaptation

Before drafting, glance at `git log -5 --oneline`. If the repo has a clear convention that differs from above (e.g. no scopes, sentence case, ticket prefixes like `[ABC-123]`), match it. The user's habit > generic Conventional Commits dogma. Note: this overrides the defaults above for subject style only — keep selective staging and the confirmation step regardless.

## Edge cases

- **Nothing to commit**: report "No changes to commit." and stop. Do not create empty commits.
- **Already partially staged**: if the user has manually staged a subset, ask "Commit only what's staged, or also include the unstaged changes?" before adding more.
- **Merge in progress**: if `.git/MERGE_HEAD` exists, this isn't a regular commit — defer to the user, do not auto-resolve.
- **Detached HEAD**: warn the user before committing — commits will be lost when they switch branches unless tagged.
- **Pre-commit hook fails**: the commit did not happen. Read the hook output, fix the underlying issue, re-stage if needed, and create a NEW commit (not `--amend`). Never bypass with `--no-verify` unless the user explicitly says to.
- **User asks for `--amend`**: only if they explicitly request it. Warn if the previous commit is already pushed.

## Boundaries

- Never push. The user pushes.
- Never sign commits or change git config.
- Never run destructive operations (`reset --hard`, `clean -f`, branch deletes).
- Never use `--no-verify` to skip hooks unless the user explicitly authorizes it for this commit.
- Never `git add -A` or `git add .` — always explicit paths.
