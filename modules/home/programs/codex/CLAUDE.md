# Codex CLI — Declarative Configuration

Home Manager's `programs.codex` module writes `~/.codex/`. This folder feeds it
Claude Code's MCP servers, rules, skills and agents (`../claude-code/`), so
both agents work from one source. Hosts opt in with
`programs.codex.enable = true;`, which `../../workstation/default.nix` sets
(Whopper, BigMac, MacFlurry). The package stays outside Home Manager
(`package = null`): Whopper installs `codex` in
`hosts/whopper/modules/packages.nix`, the Macs through the Homebrew cask in
`modules/darwin/homebrew.nix`.

```
~/.nixfiles/modules/home/programs/codex/
├── default.nix          # enable glue, plugins, hooks, settings
├── mcp.nix              # programs.mcp.servers -> Codex mcp_servers, + context7/vercel
├── instructions.nix     # ~/.codex/AGENTS.md and the tailwind skill
├── preamble.md          # top of AGENTS.md: Claude -> Codex translation, guards
├── skills.nix           # programs.codex.skills -> ~/.codex/skills/
├── agents.nix           # ~/.codex/agents/*.toml
└── agent-md-to-toml.py  # Claude agent markdown -> Codex agent TOML
```

## What goes where

| Claude Code | Codex |
|---|---|
| `programs.mcp.servers` | `config.toml` `[mcp_servers]` (`mcp.nix`) |
| `rules/common`, `rules/web/defaults.md`, `rules/typescript` | inlined into `~/.codex/AGENTS.md` after `preamble.md` |
| `rules/web/tailwind.md` (path-scoped) | the `tailwind` skill |
| `rules/rust/gpui.md` (path-scoped) | dropped; the `gpui` skill it points at is in `skills.nix` |
| both `hooks.md` rules | dropped (Claude Code settings) |
| skills | `~/.codex/skills/<name>` (`skills.nix`) |
| `agents/*.md`, caveman's `cavecrew-*` | `~/.codex/agents/<name>.toml` |
| context-mode, ponytail plugins | Codex plugins, `programs.codex.plugins` |
| `hooks/block-rm-rf.sh` | `~/.codex/hooks.json` PreToolUse `^Bash$` |
| `WebSearch` hook (searxng only) | `web_search = "disabled"` plus a line in `preamble.md` |
| i-have-adhd always-on hook | the "Output style" section of `preamble.md` |

`~/.agents/skills/` keeps the four skills `../claude-code/settings.nix` links
there (design-taste-frontend, security-audit, brag, brag-slim). Codex reads
that root too, so `skills.nix` leaves them out. New skills go in
`~/.codex/skills/` because pi also scans `~/.agents/skills/` and already gets
every Claude skill through claude-bridge.

A new Claude Code agent or rule reaches Codex only if it lands in something
this module reads. That means `../claude-code/agents/`,
`../claude-code/rules/common/` or `../claude-code/rules/typescript/` (read
whole), or `rules/web/defaults.md` and `rules/web/tailwind.md` (read by name).
A new file in `rules/web/` needs adding to `instructions.nix`. Skills are
listed one by one in `skills.nix`; Matt Pocock's come from
`../claude-code/mattpocock-skills.nix`.

Agents keep their Claude names and instructions. The Claude model tier sets
`model_reasoning_effort` (opus high, sonnet medium, haiku low). An agent whose
`tools` include neither Write nor Edit (architect, planner, code-reviewer)
gets `sandbox_mode = "read-only"`.

## MCP secrets

Claude Code expands `${VAR}` in server config and Codex does not. `mcp.nix`
rewrites each placeholder to the key Codex reads that variable from
(`bearer_token_env_var`, `env_http_headers`, `env_vars`) and fails evaluation
if one is left. Stdio servers carry no placeholder by then: `mcpLaunchEnv`
(`../claude-code/mcp-secrets.nix`) wraps them so they read their own secrets.
HTTP header values come from the shell environment that
`../claude-code/mcp.nix` and `../../workstation/mailspring.nix` export, so
Codex has to start from a shell that ran its init, and Codex agents started by
Concierge see a new key only after `concierge-daemon` restarts.

OAuth servers sign in once per machine: `codex mcp login <name>` for
`figma-almost-always`, `figma-personal`, `linear-swiss-cheese`,
`linear-almost-always`, `cloudflare-api` and `vercel`. Context7 needs no login.

## Writable state

- `config.toml` stays a real file (`mutableSettings = true`). Codex writes
  project trust, `/model`, feature toggles and hook trust there; each
  activation merges the declared keys over it. Removing a key from nix does
  not remove it from the file.
- Hooks run only after they are trusted: open `/hooks` in Codex once per
  machine and trust the block-rm-rf, context-mode and ponytail hooks. A
  changed hook (new store path) needs trusting again. Plugin hooks run under
  the stable `hooks` feature; the old `plugin_hooks` flag is removed in 0.163.
- Codex 0.163 offers to import the Claude Code configuration. Decline: the
  import writes into files this module owns.

## Not ported

- `mods/humanizer-gate` and `mods/nix-owned-paths` use Claude Code's
  in-process hook engine. `preamble.md` states both rules instead.
- `hooks/context-mode-cache-heal.mjs` fixes Claude's plugin marketplace only.
- `skills/codex-imagegen`: Codex has its own `imagegen`.
- claude.ai connectors other than Context7 and Vercel (Slack, Google
  Calendar, Claude Docs). Codex reaches Slack and Calendar as ChatGPT apps.

## Checking a change

```bash
nix build --no-link --print-out-paths \
  .#nixosConfigurations.Whopper.config.home-manager.users.psoldunov.home-files
```

Inspect `.codex/` in the result. After `rebuild_system`: `codex mcp list`,
then `/mcp`, `/skills` and `/hooks` inside `codex`.
