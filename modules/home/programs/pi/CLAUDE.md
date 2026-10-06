# Pi Coding Agent — Declarative Configuration

`~/.pi/agent/` is partly managed by home-manager. This folder holds what nix
owns there; the rest stays pi's own.

```
~/.nixfiles/modules/home/programs/pi/
├── default.nix                  # claude-bridge link + claude-bridge.json
├── CLAUDE.md                    # this file
└── extensions/claude-bridge/    # linked to ~/.pi/agent/extensions/claude-bridge/
```

Hosts opt in with `programs.pi-coding-agent.enable = true;` (Whopper sets it
in `hosts/whopper/home/packages.nix`). home-manager's own module installs the
package; `overlays/pi-coding-agent` pins the release it builds.

## What stays mutable

- `~/.pi/agent/settings.json`: pi writes it (`/model`, `/settings`,
  `pi install`). `programs.pi-coding-agent.settings` is left unset because it
  would replace the file with a read-only store symlink.
- `auth.json`, `sessions/`, `models-store.json`: credentials and runtime data.

## claude-bridge

The extension gives pi the same instructions Claude Code gets, from
`~/.claude/` (managed by `../claude-code/`), each loaded when Claude Code
would load it, so nothing floods the context up front:

| Claude Code | pi |
|---|---|
| `~/.claude/CLAUDE.md`, project `.claude/CLAUDE.md`, `CLAUDE.local.md` | prompt context files, every prompt |
| `CLAUDE.md` in a subdirectory of the working directory | appended to the first read/edit/write result under it |
| rules without `paths:` | `claude_rules` system-prompt section |
| rules with `paths:` | appended to the first read/edit/write result of a matching file |
| skills (user, plugin manifest paths, project) | pi's skill listing (name + description), trimmed to Claude Code's `skillListingBudgetFraction` / `skillListingMaxDescChars`; `/name` and `/plugin:name` aliases |
| agents (user, plugin, project, built-in general-purpose/Explore/Plan) | `Agent` tool with Claude Code's schema; the body is the child's system prompt only |

- A lazy block carries a marker (`<claude-rule id=…>`, `<claude-memory id=…>`)
  and is not repeated while the marker is still in context. After compaction
  removes it, the next matching file brings it back, as in Claude Code.
- Project `.claude/` is read only once pi trusts the project.
- Each `Agent` call runs `pi --mode json -p --no-session` on the session's
  model and thinking level. Claude tool names map to pi's (Glob -> find,
  MultiEdit -> edit, ...). Tools with no pi counterpart are dropped. Children
  do not get the `Agent` tool themselves (`agents.maxDepth`).
- Tune it in `default.nix` (`claudeBridge` attrset): skill/agent excludes,
  tier -> model map, caps. Every key is optional; defaults live in
  `extensions/claude-bridge/config.ts`.
- `/claude-bridge` in pi shows what loaded, what was excluded and why, the
  skill listing size vs budget, and what has been injected in this branch.

Not bridged yet: Claude Code hooks (caveman, i-have-adhd, block-rm-rf,
impeccable), MCP servers, plugin slash commands, and settings such as
`effortLevel`.

## Working on the extension

- Plain TypeScript loaded by pi through jiti, so there is no build step.
- Modules other than `index.ts` and `agent-tool.ts` import nothing from pi.
  `parseFrontmatter` is passed in, so they run under plain Node.
- Tests: `node --test 'modules/home/programs/pi/extensions/claude-bridge/tests/*.test.ts'`
  (Node 24 strips the types). Keep to erasable TypeScript syntax and `.ts`
  import specifiers.
- Try a change before rebuilding:
  `pi -e ./modules/home/programs/pi/extensions/claude-bridge/index.ts`, then
  `/claude-bridge`.
- pi's extension API docs and examples ship with the package under
  `lib/node_modules/pi-monorepo/{docs,examples}`. The `Agent` tool's process
  handling is adapted from `examples/extensions/subagent`.
