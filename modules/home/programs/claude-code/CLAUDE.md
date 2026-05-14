# Claude Code — Declarative Configuration

This installation is managed **declaratively** via NixOS + home-manager. Do not
hand-edit files under `~/.claude/` that this setup owns — your changes will be
overwritten on the next system rebuild.

## Where config lives

All Claude Code state that's declaratively managed lives in:

```
~/.nixfiles/modules/home/programs/claude-code/
├── default.nix          # programs.claude-code settings, plugins, MCP servers
├── CLAUDE.md            # this file (rendered to ~/.claude/CLAUDE.md)
├── agents/              # symlinked to ~/.claude/agents/
├── commands/            # symlinked to ~/.claude/commands/
├── hooks/               # symlinked to ~/.claude/hooks/
└── skills/              # symlinked to ~/.claude/skills/
```

The nix module that wires it: `home-manager`'s `programs.claude-code`
([options reference](https://home-manager-options.extranix.com/?query=claude-code&release=master)).

## Workflow

To change anything Claude Code-related:

1. Edit files under `~/.nixfiles/modules/home/programs/claude-code/`.
2. Rebuild: `rebuild_system` (or `sudo nixos-rebuild switch --flake ~/.nixfiles#Whopper`).
3. On conflict with an existing real file at `~/.claude/<path>`, home-manager
   renames it to `<path>.hm-backup` (configured via
   `home-manager.backupFileExtension = "hm-backup"` in `~/.nixfiles/flake.nix`)
   and writes the new symlink. Inspect and delete the backup once verified.

## What's NOT declarative

Some `~/.claude/` paths remain user-mutable across rebuilds — don't worry about
them:

- `~/.claude/projects/` — per-project session memory.
- `~/.claude/history.jsonl`, `~/.claude/sessions/` — conversation history.
- `~/.claude/plans/` — generated plans from the `plan` skill.
- `~/.claude/plugins/cache/` — installed plugin payloads (the *which plugins
  are enabled* lives in nix; the cached payloads themselves don't).
- `~/.claude/.credentials.json` — auth tokens.
- `~/.claude/telemetry/`, `~/.claude/file-history/`, `~/.claude/backups/` — runtime data.

Anything else under `~/.claude/` is fair game to be replaced by nix on next rebuild.

## Plugins

The `context-mode` plugin is installed via a flake input pinned in
`~/.nixfiles/flake.nix` and loaded through `programs.claude-code.plugins`.
Updating it:

```bash
nix flake update context-mode
rebuild_system
```

Marketplace-installed plugins (`skill-creator`, `superpowers`, `figma`,
`Notion`, `vercel`) are enabled via `settings.enabledPlugins` in `default.nix`.
Their cached payloads live under `~/.claude/plugins/cache/` and update
independently via Claude Code's own plugin update mechanism.

## MCP servers

User-level MCP servers are declared in `programs.claude-code.mcpServers` (none
currently). MCP capabilities for `context7`, `figma`, `notion`, `vercel`,
`context-mode` come from the corresponding plugins.

## Hooks

Hook *registration* (which event triggers which command) lives in nix under
`settings.hooks`. The hook *scripts* themselves currently still live at
`~/.claude/hooks/*.ts` and `*.mjs` — those will be migrated into the nix repo
later. They're invoked by absolute path from settings.json.

## Notes for future Claude sessions

If you're editing Claude Code config: edit the nix module, not `~/.claude/`.
If a setting doesn't survive a rebuild, that's the signal to declare it
declaratively rather than tweak it imperatively.
