# Git Workflow

## Commit Message Format
```
<type>: <description>

<optional body>
```

Types: feat, fix, refactor, docs, test, chore, perf, ci

## No Attribution

Attribution is disabled globally (`attribution` in
`~/.nixfiles/modules/home/programs/claude-code/settings.nix`). Never write
attribution by hand either: no `Co-Authored-By: Claude ...` trailer in commits,
no "Generated with Claude Code" footer or session link in PR bodies, and none in
text written for child agents or squash-merge messages.

## Pull Request Workflow

When creating PRs:
1. Analyze full commit history (not just latest commit)
2. Use `git diff [base-branch]...HEAD` to see all changes
3. Draft comprehensive PR summary
4. Include test plan with TODOs
5. Push with `-u` flag if new branch

> For the full development process (planning, TDD, code review) before git operations,
> see [development-workflow.md](./development-workflow.md).
