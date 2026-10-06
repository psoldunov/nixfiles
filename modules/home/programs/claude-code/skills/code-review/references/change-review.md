# Change Review

Reviews the change in front of you: what a branch, an Ensemblr workspace or a pull request adds
on top of its base. The question it answers is "is this change ready to merge?", not "is this
codebase well designed?". That second question belongs to `references/codebase-review.md`.

---

## Step 1: Pin the scope

Take the first row that applies. When the user narrowed the scope themselves ("just
`src/auth`", "only the last commit"), honor that over the table.

| Context | Scope | How to read it |
|---------|-------|----------------|
| The user named a pull request (number or URL) | that pull request | `gh pr view <n>`, `gh pr diff <n>` |
| The user asked for uncommitted work only ("review before commit", "what I just did") | the working tree | `git diff --staged`, `git diff`, and each untracked file from `git status --porcelain` |
| Inside Ensemblr: an `ensemblr_get_workspace_diff` tool exists, under whatever prefix your client gives it | the workspace diff: every commit on the branch plus uncommitted work, against the workspace's base | "Inside Ensemblr" below |
| Any other git repository | the branch against its base, plus uncommitted work | "Outside Ensemblr" below |

### Inside Ensemblr

1. Call `ensemblr_get_workspace_diff` with `stat: true`. It returns `baseRef`, the merge target
   the Changes panel measures against, and each changed file with its +/- counts. Use `baseRef`
   as the base. Do not re-derive it from `origin/HEAD`: the user can retarget a workspace's base.
2. Read the patch. Read the whole diff when it is small, else one file at a time with
   `filePath`. A full read is capped and lists what it dropped in `omittedFiles`. Request each
   of those by `filePath`.
3. Call `ensemblr_get_diff_comments` for the comments already on the diff. An open comment from
   the user shows what they care about. Never file a duplicate of a comment already there.
4. List the branch's own commits for the branch-level checks:
   `git log --no-merges --reverse --format='%h %s' <baseRef>..HEAD`.

### Outside Ensemblr

Run these one at a time and fill in each placeholder from the previous answer:

```bash
git branch --show-current
git symbolic-ref --quiet --short refs/remotes/origin/HEAD   # <base>, e.g. origin/main; if unset, try origin/main, then origin/master
git merge-base HEAD <base>
git log --no-merges --reverse --format='%h %s' <merge-base>..HEAD
git diff --stat <merge-base>                                # committed and uncommitted changes against the fork point
git status --porcelain                                      # untracked files: read each new one
```

The scope is `git diff <merge-base>` (tracked changes, committed or not) plus every untracked
file.

### Scope edge cases

- **Empty scope**: say there is nothing to review. Offer the last commit (`git show HEAD`), a
  named range or a codebase review, but do not start one.
- **Not a git repository**: ask what to review instead: a file, a directory or pasted code.
- **On the base branch itself**: there is no branch to review. Review the uncommitted work only.
- **Detached HEAD outside Ensemblr**: ask which base to compare against. Do not guess.
- **Branch behind its base**: say so in the report. Never rebase or merge the base in to catch up.
- **Merge commits from the base**: `--no-merges` keeps the commit list to the branch's own work.
  The diff against the merge base already leaves out what the base contributed.
- **Mixed work in progress**: a feature plus an unrelated refactor plus debug prints is a
  finding in its own right (scope drift). Report it; don't review around it.

---

## Step 2: Size the pass

Ground every finding in how the change fits the system. For each changed file, read its
imports, its call sites and its tests, not only the diff hunks.

Who reads the diff depends on the host:

- **Inside Ensemblr**: review a small diff (one reading holds it) yourself. Split a wide diff
  by area and hand each slice to a child conversation under the playbook's delegation rules.
- **Outside Ensemblr, with the `Agent` tool**: hand the diff to the `code-reviewer` subagent
  (`subagent_type: "code-reviewer"`), even a small one. Its file reading stays out of the main
  conversation, which gets only the report. For a wide diff, launch one subagent per slice, all
  in the same message so they run in parallel.
- **No delegation tool at all**: review it yourself, one slice at a time.

Brief each reader with the template in Step 3, its file list, the base and the commit list.
Keep the branch-level checks and the verdict yourself. Whatever the host:

- **Massive diff** (hundreds of files): ask the user to narrow it to a directory or a commit
  range. When nobody is there to ask, start with the highest-risk areas and name what you
  skipped.
- **Verify before you report.** A reader's finding is a claim. Open the cited line, confirm it,
  and drop what does not hold up.

---

## Step 3: The reader brief

Use this whether you read the diff yourself or brief a reader. Fill in the scope block, keep the
persona framing and the deliverable.

```
You are operating as the MOST SENIOR code reviewer on this team — a staff/principal engineer
with 20+ years shipping production systems. You have seen every subtle bug, security hole,
race condition, and architectural mistake. You review with the care of someone whose name
goes on the release notes. You are kind but uncompromising: you do not rubber-stamp, you do
not hedge, and you do not invent problems just to look thorough.

## Scope

Branch:    <branch-name>
Base:      <base> (merge base: <short-sha>)
Commits:   <N> commits
Files:     <M> files changed (+<adds> -<dels>), plus uncommitted work: <yes/no>
Slice:     <the files this reader owns, or "whole diff">

Read the changed files' surrounding code (imports, call sites, related tests) so the review
is grounded in how the change fits the system. If you are not the code-reviewer subagent,
read ~/.claude/agents/code-reviewer.md first: it carries the full checklist and the
"Conventions & Rules" section.

## What to look for

Apply the full checklist (security, correctness, code quality, framework patterns,
performance, maintainability, rule and convention compliance). Lead with what would make a
senior engineer block the merge:

- Security vulnerabilities (injection, auth bypass, secret exposure, unsafe deserialization)
- Correctness bugs (off-by-one, race conditions, swallowed errors, broken invariants)
- Data-loss or destructive operations without safeguards
- Hidden coupling or architectural drift the change introduces
- Behavioural regressions in the surrounding code
- Missing tests for new behaviour
- Violations of the repository's own conventions and rule files

Branch-level concerns:

- Scope drift: unrelated changes that belong in a separate PR
- Commit hygiene: "WIP", "fix" or "." messages to squash or reword before the PR
- Churn: files added then deleted, or rewritten across commits
- Leftovers: console.log, dbg!, print(...), commented-out code, TODO in critical paths
- Test coverage delta: tests in proportion to the new behaviour
- Migration safety: can each DB migration run online, and is it reversible?
- Public API changes: breaking changes to exported functions, types or routes

Skip stylistic noise. Skip issues in unchanged code unless they are CRITICAL. Consolidate
similar findings. Only report what you are >80% confident is a real problem.

## Output

Findings by severity (CRITICAL → HIGH → MEDIUM → LOW), each as:

  [SEVERITY] Short title
  File: path/to/file.ext:LINE
  Commit: <short-sha> (when the issue sits in one commit)
  Issue: what is wrong and why it matters in this codebase
  Fix: concrete suggestion, with a before/after snippet when useful

Then a "Branch-level findings" block for what has no file and line (scope drift, commit
hygiene, churn). Then a summary table:

  | Severity | Count | Status |
  |----------|-------|--------|
  | CRITICAL | N     | ...    |
  | HIGH     | N     | ...    |
  | MEDIUM   | N     | ...    |
  | LOW      | N     | ...    |

Be direct. If the change is clean, say so plainly and briefly.
```

---

## Step 4: Report

Put both verdicts at the top of your message, then the findings in the format above. Don't
summarize the findings away: the structured detail is the value.

- **Code verdict**: APPROVE (no CRITICAL or HIGH), WARNING (HIGH only: mergeable with explicit
  acknowledgment) or BLOCK (any CRITICAL: fix before merge).
- **PR readiness**: READY or NOT READY. When NOT READY, name the single biggest blocker.

**Inside Ensemblr, also file the findings on the diff.** Every finding with a file goes into
one batched `ensemblr_add_diff_comments` call:

- `filePath`: the path from the workspace root.
- `lineNumber`: the line in the changed file, or `null` for a file-level finding.
- `body`: `[SEVERITY] Short title. Issue. Fix: ...`

The user reads those comments as a list in the Checks panel. Branch-level findings stay in the
report, because they have no line to anchor to. When readers worked slices, they report to you.
You file the comments once, after you verify each one, so nothing is filed twice.

**Outside Ensemblr, the report is the whole deliverable.** Never post findings to a GitHub pull
request unless the user asks for that.

---

## Step 5: After the report

- **Do not fix, commit, rebase or open a PR unasked.** Fix only when the user, or the workflow
  driving you, asks for it. When CRITICAL or HIGH findings stand, offer to fix them. When the
  change is READY, offer to open the PR, and ask before you run `gh pr create`.
- **Ensemblr's Review conversation shares the worktree** with the orchestrator that owns the
  branch. That orchestrator commits. Never commit, rebase or move HEAD from the Review
  conversation.
- **When asked to fix**: make the fix in the working tree and rerun the repository's checks.
  Inside Ensemblr, then resolve (`ensemblr_resolve_diff_comments`) only the comments you
  actually fixed. A comment you deferred or disagree with stays open. Either way, your reply
  says which findings you left and why.
- **Re-review after fixes** covers the changed lines and anything they touch, not the whole
  diff again. Use a full pass only when the fixes reshaped the change.
