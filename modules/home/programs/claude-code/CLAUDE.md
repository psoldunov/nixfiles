# Claude Code — Declarative Configuration

This installation is managed **declaratively** via NixOS + home-manager. Do not
hand-edit files under `~/.claude/` that this setup owns — your changes will be
overwritten on the next system rebuild.

## Where config lives

All Claude Code state that's declaratively managed lives in:

```
~/.nixfiles/modules/home/programs/claude-code/
├── default.nix          # imports the modules below
├── mcp.nix              # sops secrets, env wiring, programs.mcp servers
├── mutable-settings.nix # merges settings.nix into a writable settings.json
├── settings.nix         # programs.claude-code settings, plugins, hooks
├── global-CLAUDE.md     # rendered to ~/.claude/CLAUDE.md (every project)
├── CLAUDE.md            # this file (loads only when working in this folder)
├── agents/              # symlinked to ~/.claude/agents/
├── hooks/               # symlinked to ~/.claude/hooks/
├── mods/                # local function-hook plugins
├── rules/               # symlinked to ~/.claude/rules/
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
- `~/.claude/plans/` — plans written in plan mode.
- `~/.claude/plugins/cache/` — installed plugin payloads (the *which plugins
  are enabled* lives in nix; the cached payloads themselves don't).
- `~/.claude/.credentials.json` — auth tokens.
- `~/.claude/telemetry/`, `~/.claude/file-history/`, `~/.claude/backups/` — runtime data.
- `~/.impeccable/` — the Impeccable engine binary cache.

Anything else under `~/.claude/` is fair game to be replaced by nix on next rebuild.

## settings.json is writable

`~/.claude/settings.json` is a real file, not a nix-store symlink, so `/model`,
`/plugin`, `/permissions`, `/hooks` and `/statusline` can save their changes.
On each rebuild, `mutable-settings.nix` deep-merges the declared
`programs.claude-code.settings` into it:

- Scalar keys declared in nix win over the live file.
- Arrays (permissions, hooks) are unioned, so entries the CLI added survive.
  Duplicate entries collapse to their first occurrence.
- Keys only the CLI set are left alone.

Removing an array entry from nix does not remove it from the live file. Delete
it from `~/.claude/settings.json` by hand as well. To make a CLI change
permanent, copy it into `settings.nix`.

## Package version

The `claude-code` binary tracks Anthropic's `latest` release channel, not
nixpkgs. `~/.nixfiles/overlays/claude-code/` swaps the pinned release manifest
into nixpkgs' package; nixpkgs' own version wins if it is newer. Bump it:

```bash
update_claude_code            # or: update_claude_code <version>
rebuild_system
```

`update_system` runs `update_claude_code` on its own.

## Plugins

The `context-mode` plugin is installed via a flake input pinned in
`~/.nixfiles/flake.nix`. The `plugins` set in `settings.nix` links it whole
into `~/.claude/skills/context-mode/`, where Claude Code loads it as a
skills-directory plugin. Updating it:

```bash
nix flake update context-mode
rebuild_system
```

`caveman`, `impeccable`, `taste-skill` and `i-have-adhd` are wired the same way. The
`impeccable` repo is a marketplace, so `settings.nix` points at its `plugin/`
subdirectory.

The plugins deliberately skip `programs.claude-code.plugins`. That option
rebuilds each plugin as a directory of per-entry symlinks, and Claude Code
refuses any manifest path (`./skills/`, a hooks module) whose real location
falls outside the plugin directory. Check that every plugin loads with
`claude plugin list`.

Never install a marketplace copy of one of these plugins. An installed
marketplace plugin takes the name, and the nix copy then does not load. Its hooks run a launcher that downloads the matching engine
binary into `~/.impeccable/bin/<version>/` on first use; that cache is not
declarative. `taste-skill` is skills only (frontend design taste, redesign,
image-to-code, brand kits), with no hooks or MCP servers.

`i-have-adhd` shapes answers for an ADHD reader: next action first, numbered
steps, one closing next action. Its SessionStart hook injects the full ruleset
only when `~/.claude/.i-have-adhd-always` exists, and `settings.nix` declares
that flag file. `hooks/adhd-final-response.sh` re-asserts the rules on every
prompt so they shape each turn's final message, and takes precedence over
caveman on structure. Delete the flag entry in `settings.nix` to switch both
hooks off; "stop adhd mode" switches it off for one session.

Local mods (Claude Code function-hook plugins) live in `mods/<name>/` and are
linked through the same `plugins` set. Each one has
`.claude-plugin/plugin.json`, `hooks/hooks.json` naming its module, and tests
under `tests/`. Check one with `claude plugin validate mods/<name>` and
`claude plugin test mods/<name>`. `nix-owned-paths` refuses Edit, Write and
NotebookEdit calls on files that resolve into `/nix/store`, and names the
source under this module to edit instead.

Microsoft's official `playwright-cli` skill comes from the `playwright-cli`
flake input too. `settings.nix` links its `skills/playwright-cli/` directory
into `~/.claude/skills/playwright-cli/`, next to the local skills. Update it
with `nix flake update playwright-cli`.

## MCP servers

User-level MCP servers are declared in `programs.mcp.servers` in `mcp.nix`
(host-specific ones, such as Playwright, live in the host's home config).
`enableMcpIntegration` feeds them to Claude Code. `figma-almost-always` and
`figma-personal` are two remote Figma servers, one per Figma account. Sign in
to each one separately through `/mcp`. The `context-mode` MCP server comes
from its plugin. Context7, Vercel, Claude Docs and the other `claude.ai`
servers are connectors on the claude.ai account, managed at claude.ai →
Settings → Connectors rather than in nix.

## Hooks

Hook scripts live in `hooks/` and are linked into `~/.claude/hooks/` by
`programs.claude-code.hooks`. Their registration (which event triggers which
command) lives in `settings.hooks` in `settings.nix`.

`adhd-final-response.sh` (UserPromptSubmit) prints the i-have-adhd reminder
when the plugin's opt-in flag exists, and stays silent otherwise.

`context-mode-cache-heal.mjs` is a vendored copy of the script context-mode
deploys for its marketplace install. context-mode rewrites the hook's command
in `settings.json` to the quoted bare-script form on every boot, so
`settings.nix` declares that exact string. Any other spelling makes the array
union append a fresh copy on each rebuild.

## Shared with pi

pi reads the same `CLAUDE.md`, rules, skills and agents through its
claude-bridge extension (`../pi/`). A change here reaches pi after the same
rebuild. Skills and agents that need Claude-only features (hooks, MCP tools)
are excluded or tuned in `../pi/default.nix`.

## Notes for future Claude sessions

If you're editing Claude Code config: edit the nix module, not `~/.claude/`.
If a setting doesn't survive a rebuild, that's the signal to declare it
declaratively rather than tweak it imperatively.
