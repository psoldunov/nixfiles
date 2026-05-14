---
name: plan
description: Create a comprehensive implementation plan for a feature, refactoring, or complex task. Use when the user wants to plan before coding.
disable-model-invocation: true
hooks:
  PostToolUse:
    - matcher: "Write"
      hooks:
        - type: command
          command: "./hooks/open-preview.sh"
---

## Input

$ARGUMENTS

## Instructions

If `$ARGUMENTS` is empty or contains only whitespace, ask the user:

> What would you like to plan? Please describe the feature, refactoring, or task you'd like an implementation plan for.

Then stop. Do NOT proceed without a description.

If `$ARGUMENTS` is provided:

### Step 1: Delegate to planner agent

Use the Agent tool with the **planner** agent (subagent_type from agents/planner.md). Pass:
- The full `$ARGUMENTS` as the planning request
- The current context below so the planner knows the environment

The planner agent will analyze the codebase and produce a structured plan following this format:
- Overview (2-3 sentence summary)
- Requirements
- Architecture Changes (with file paths)
- Implementation Steps broken into Phases, each step with: Action, Why, Dependencies, Risk
- Testing Strategy (unit, integration, E2E)
- Risks & Mitigations
- Success Criteria

### Step 2: Save the plan (no prompting)

After receiving the plan from the planner agent, save it immediately without asking the user for confirmation, filename, or location.

1. Determine the plans directory:
   - If inside a git repo / project, use `.claude/plans/` at the project root
   - Otherwise fall back to `~/.claude/plans/`
2. Create the directory if it does not exist (use the Write tool — it creates parent directories automatically). Do **not** prompt the user.
3. Save the plan as `YYYY-MM-DD-<slug>.md` where `<slug>` is a kebab-case short name derived from the feature description. If a file with that name already exists, append `-2`, `-3`, etc.
4. Use the Write tool directly — never ask "should I save this?" or "what should I name it?".
5. If the project is a git repo, ensure `.claude/plans/` is gitignored. Check the project root `.gitignore`:
   - If `.gitignore` does not exist, create it with a single line `.claude/plans/`
   - If it exists but does not already contain `.claude/plans/` (or a parent like `.claude/`), append `.claude/plans/` on a new line
   - Do not modify `.gitignore` if the path is already ignored, and do not touch it at all when using the `~/.claude/plans/` fallback

### Step 3: Open the plan in preview mode (handled by skill-scoped hook)

Preview opening is delegated to the `PostToolUse` hook declared in this
skill's frontmatter, which invokes [`./hooks/open-preview.sh`](./hooks/open-preview.sh).
The hook is scoped to this skill's lifecycle — it only runs while the `plan`
skill is active, so it cannot interfere with unrelated Write calls in other
sessions.

The script filters for `file_path` matching `**/.claude/plans/*.md`, probes
for an available IDE CLI (`code` / `cursor` / `windsurf` / `code-insiders`),
opens the file in a reused window, and on macOS dispatches `Markdown: Open
Preview` through the Command Palette.

Do not attempt to open the preview from the skill body itself. Skip this
step — the hook fires automatically after Step 2's Write completes.

### Step 4: Create trackable task list

Use TodoWrite to create a trackable task list from the implementation steps in the plan. Each phase/step should become a todo item so progress can be tracked during implementation.

## Current Context
- Branch: !`git branch --show-current 2>/dev/null || echo "not a git repo"`
- Working directory: !`pwd`
- Date: !`date +%Y-%m-%d`
- Existing plans: !`ls .claude/plans/ 2>/dev/null || echo "no plans directory yet"`
