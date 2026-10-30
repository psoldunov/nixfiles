# Claude Code — Declarative Configuration

This installation is managed **declaratively** via home-manager, on NixOS
(Whopper, BigTasty) and nix-darwin (BigMac, MacFlurry). Do not
hand-edit files under `~/.claude/` that this setup owns — your changes will be
overwritten on the next system rebuild.

## Where config lives

All Claude Code state that's declaratively managed lives in:

```
~/.nixfiles/modules/home/programs/claude-code/
├── default.nix          # imports the modules below
├── mattpocock-skills.nix # Matt Pocock skills to link (Claude Code, pi, Codex)
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
2. Rebuild: `rebuild_system` (or `sudo nixos-rebuild switch --flake ~/.nixfiles#Whopper`;
   on a Mac `sudo darwin-rebuild switch --flake ~/.nixfiles#<BigMac|MacFlurry>`).
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

`caveman`, `impeccable`, `i-have-adhd` and `ponytail` are wired the same way.
The `impeccable` repo is a marketplace, so `settings.nix` points at its
`plugin/` subdirectory.

The plugins deliberately skip `programs.claude-code.plugins`. That option
rebuilds each plugin as a directory of per-entry symlinks, and Claude Code
refuses any manifest path (`./skills/`, a hooks module) whose real location
falls outside the plugin directory. Check that every plugin loads with
`claude plugin list`.

Never install a marketplace copy of one of these plugins. An installed
marketplace plugin takes the name, and the nix copy then does not load. Its hooks run a launcher that downloads the matching engine
binary into `~/.impeccable/bin/<version>/` on first use; that cache is not
declarative.

`taste-skill` v2 provides one skill, `design-taste-frontend`, with no hooks or
MCP servers. Its repo has a marketplace manifest but no plugin manifest, so
`settings.nix` links `skills/taste-skill/` directly into both
`~/.claude/skills/design-taste-frontend/` (Claude Code and pi's claude-bridge)
and `~/.agents/skills/design-taste-frontend/` (Codex and Pi's native discovery).
Both links preserve its scripts, references and assets. Linking the whole
repo hides the nested skill from Claude Code and pi's claude-bridge. Update
it with `nix flake update taste-skill` and `rebuild_system`.

Cloudflare's `security-audit` skill (github.com/cloudflare/security-audit-skill)
is wired the same way from the `security-audit-skill` input: its
`skills/security-audit/` is linked into `~/.claude/skills/security-audit/` and
`~/.agents/skills/security-audit/`. It is guidance by default; the full
six-phase audit (which writes report files and runs its `validate-*.cjs`
checks with `node`) runs only when asked for an audit or pen test. Update it
with `nix flake update security-audit-skill` and `rebuild_system`.

latent-spaces' `brag` and `brag-slim` skills (github.com/latent-spaces/brag)
come from the `brag` input the same way: `skills/brag/` and `skills/brag-slim/`
are linked into `~/.claude/skills/` and `~/.agents/skills/`. Skip the repo's
marketplace plugin, which would shadow these copies. Both turn a project or
site into a short launch video in `brag-output/` and need `node`, `npx` and
`ffmpeg` on `PATH`. On Opus 5.5, `/brag` hands off to its bundled copy of
`/brag-slim`; on other models it runs the full workflow through `npx
hyperframes`, whose helper skills (`npx hyperframes skills`) are not wired
here. Update with `nix flake update brag` and `rebuild_system`.

`i-have-adhd` shapes answers for an ADHD reader: next action first, numbered
steps, one closing next action. Its SessionStart hook injects the full ruleset
only when `~/.claude/.i-have-adhd-always` exists, and `settings.nix` declares
that flag file. `hooks/adhd-final-response.sh` re-asserts the rules on every
prompt so they shape each turn's final message, and takes precedence over
caveman on structure. Delete the flag entry in `settings.nix` to switch both
hooks off; "stop adhd mode" switches it off for one session.

`ponytail` (github.com/DietrichGebert/ponytail) steers code toward the
smallest change that works: reuse what exists, stdlib before new code, one
small test for risky logic. Its SessionStart hook injects the ruleset at the
default level (`full`) and a short map of the repo; SubagentStart gives
subagents the ruleset too. `/ponytail lite|full|ultra|off` changes the level,
`/ponytail-review` and `/ponytail-audit` review a diff or the whole repo. The
hooks run `node` from `PATH`. It also registers a band above the prompt (cost,
tokens, tests) and writes one CSV row per task to `~/.config/ponytail/band/`;
`/ponytail band` hides the band. Nothing leaves the machine unless a webhook
URL is set in its plugin config. The same checkout is pi's `ponytail`
extension (`../pi/default.nix`). Update both with `nix flake update ponytail`.

Local mods (Claude Code function-hook plugins) live in `mods/<name>/` and are
linked through the same `plugins` set. Each one has
`.claude-plugin/plugin.json`, `hooks/hooks.json` naming its module, and tests
under `tests/`. Check one with `claude plugin validate mods/<name>` and
`claude plugin test mods/<name>`. `nix-owned-paths` refuses Edit, Write and
NotebookEdit calls on files that resolve into `/nix/store`, and names the
source under this module to edit instead.

`humanizer-gate` enforces `rules/common/human-facing-text.md`. It refuses the
first human-facing write or send in each loop (the main conversation and each
subagent) until the `humanizer` skill is loaded, and again after a compaction
drops the skill. That covers docs, READMEs, `gh pr`/`gh issue` bodies, and
Slack, Linear and Sanity calls. `hooks/policy.ts` decides what counts. The
same folder is also pi's `humanizer-gate` extension: pi loads its root
`index.ts`, which imports the same policy. `claude plugin test` skips the pi
side; test that with
`node --test modules/home/programs/claude-code/mods/humanizer-gate/tests/pi-extension.node.ts`.

Microsoft's official `playwright-cli` skill comes from the `playwright-cli`
flake input too. `settings.nix` links its `skills/playwright-cli/` directory
into `~/.claude/skills/playwright-cli/`, next to the local skills. Update it
with `nix flake update playwright-cli`.

The `humanizer` skill comes from blader's repo (github.com/blader/humanizer),
the `humanizer` input. Its root is the skill, but it also holds a
`.claude-plugin` manifest that would load it as `humanizer:humanizer`, so
`settings.nix` links only `SKILL.md` into `~/.claude/skills/humanizer/`
(Claude Code and pi's claude-bridge). `../codex/skills.nix` links the whole
root, which adds the `agents/openai.yaml` Codex reads. Keep the name plain
`humanizer`: `rules/common/human-facing-text.md` and `humanizer-gate` load it
by that name. `update_system` refreshes it with the other inputs; on its own,
`nix flake update humanizer` and `rebuild_system`.

Matt Pocock's skills come from the `mattpocock-skills` input, linked the
same way. `mattpocock-skills.nix` lists each one (name -> folder), and both
`settings.nix` and `../codex/skills.nix` link from that list, so a skill is
added in one place. Some only call the Skill tool on another (`grill-me` ->
`grilling`, `tdd` -> `codebase-design`), so keep a target listed with its
caller. Skip the repo's marketplace plugin and his issue-tracker pipeline
(`to-spec`, `to-tickets`, `implement*`, `wayfinder`, `triage`): they expect
a per-repo GitHub or GitLab setup, and his `code-review` collides with the
local one. Update with `nix flake update mattpocock-skills`.

Where his skills overlap ours, his won and ours went:

- `tdd` replaced the `tdd-guide` agent; the testing and workflow rules point
  at the skill. The 80% coverage target stays.
- `diagnosing-bugs` beats caveman's `investigate-first`. That one is part of
  the caveman plugin, so `permissions.deny` blocks it in Claude Code, pi's
  claude-bridge excludes it and Codex skips it.
- `improve-codebase-architecture` and `codebase-design` replaced the local
  `code-review` skill's codebase mode. `code-review` now reads that skill's
  `SKILL.md` from the sibling folder, since a user-invoked skill cannot be
  called through the Skill tool.
- `retro` replaced the `harness-optimizer` agent.
- `pr` sets the PR body shape that `rules/common/git-workflow.md` asks for.

## MCP servers

User-level MCP servers are declared in `programs.mcp.servers` in `mcp.nix`.
Playwright and Mailspring live in `../../workstation/` (Whopper and the Macs,
not BigTasty), with macOS paths for Chrome and Mailspring on the Macs.
`enableMcpIntegration` feeds them to Claude Code. `figma-almost-always` and
`figma-personal` are two remote Figma servers, one per Figma account.
`linear-swiss-cheese` and `linear-almost-always` do the same for the two
Linear workspaces. Sign in to each one separately through `/mcp`.
`clockify` is Clockify's hosted server, authenticated with the personal API
key in `CLOCKIFY_API_KEY` (`secrets/shared.yaml`); no sign-in needed.
`clokkr` is the local Clokkr time tracker's `clokkr mcp` stdio server. It is
declared per host, next to Clokkr itself: Whopper runs the flake package
(`hosts/whopper/home/programs/clokkr.nix`), BigMac the CLI inside
`Clokkr.app` (`hosts/bigmac/home/programs/clokkr.nix`).

`cloudflare-api` is Cloudflare's remote API server
(`https://mcp.cloudflare.com/mcp`). It has three tools: `search()` and
`execute()` run code against the whole Cloudflare API, Zero Trust tunnels
included, and `docs()` searches the developer docs. Sign in through `/mcp`;
the OAuth screen chooses which permissions the agent gets.
`CFD_MAIN_TUNNEL`'s public hostnames are managed in the dashboard, so add
them there or through this server; Nix `ingress` entries have no effect.

`searxng` is nixpkgs' `mcp-searxng` (stdio) pointed at BigTasty's SearXNG
(`hosts/bigtasty/modules/services/searxng.nix`). `SEARXNG_URL`
(`secrets/shared.yaml`) is `https://psoldunov:<password>@search.theswisscheese.com`;
the login is nginx Basic Auth in front of SearXNG, and its hashed half is
`SEARXNG_HTPASSWD` in `secrets/bigtasty.yaml` (`htpasswd -nim psoldunov`; apr1,
since nixpkgs' nginx cannot check bcrypt). Rotate both together. The shell
exports the same variable for the JSON API:
`curl "$SEARXNG_URL/search?q=<query>&format=json"`.

### MCP secrets

Never let an MCP server depend on a secret in the client's environment. A
client fills `${VAR}` from the environment it started with, and Concierge's
daemon hands the Claude Code and Codex agents it starts the environment it
captured at its own start. A secret added to the shell exports after that
never reaches them: on 2026-10-30, Concierge tasks got the literal
`${SEARXNG_URL}` and `${FIRECRAWL_API_KEY}` until the daemon restarted.

`mcp-secrets.nix` reads every placeholder in `programs.mcp.servers` at launch
instead:

- HTTP servers need nothing extra. Write the header as
  `"Bearer \${MY_KEY}"`; Claude Code's copy of the server moves it into a
  generated `headersHelper` that reads the value on every connect. Codex and pi
  cannot run a helper, so they still take the shell export.
- Stdio servers go through `mcpLaunchEnv "<name>" { command; args; env.MY_KEY =
  "\${MY_KEY}"; }` (a module argument, see searxng and Paperless in `mcp.nix`).
  The wrapper reads the value before it starts the server, for every client.
  Each env value must be a single `${VAR}`.
- A sops secret's reader is `cat` on its decrypted file, so adding the secret
  to `sops.secrets` is enough. Anything else needs
  `programs.claude-code.mcpSecretReaders.<VAR>`, a shell command that prints
  the value (Mailspring's token, read from its own config, in
  `../../workstation/mailspring.nix`).

Evaluation fails on a placeholder with no reader, and on one outside an HTTP
header, such as a stdio server missing `mcpLaunchEnv`. Keep the shell export
loops in `mcp.nix` in step for Codex, pi and scripts. Codex agents that
Concierge starts still read HTTP keys from the daemon's environment, so a new
HTTP key reaches them only after `systemctl --user restart concierge-daemon`.

`rea` is REA (github.com/morluto/rea), a reverse-engineering server. It runs
`npx -y rea-agents@<version> mcp` on Node 24, where `<version>` comes from the
`package.json` of the `rea` flake input, and that same checkout supplies the
`reverse-engineer-anything` skill (linked in `settings.nix`). Server and skill
therefore stay on one release. Bump both by editing the tag in `flake.nix`'s
`rea` input, then `nix flake update rea` and `rebuild_system`. Native targets
use nixpkgs' Ghidra (`GHIDRA_INSTALL_DIR`, JDK 21 as `JAVA_HOME`); REA accepts
Ghidra 12.1.x only, so check `pkgs.ghidra.version` after a nixpkgs bump.
Hopper is not wired: its Linux installer only handles deb, rpm and Arch
packages. Never run `rea setup` or `rea uninstall`: they rewrite agent
configs and skills that nix owns. `npx -y rea-agents@<version> doctor
--provider ghidra --json`, run with the same two variables set, is safe. The
first start downloads the package into `~/.npm/_npx`; a cold cache can outlast
Claude Code's MCP startup timeout, so reconnect through `/mcp` if it fails
once. The skill is excluded from pi, which has no MCP.

The `context-mode` MCP server comes
from its plugin. Context7, Vercel, Claude Docs and the other `claude.ai`
servers are connectors on the claude.ai account, managed at claude.ai →
Settings → Connectors rather than in nix.

## Hooks

Hook scripts live in `hooks/` and are linked into `~/.claude/hooks/` by
`programs.claude-code.hooks`. Their registration (which event triggers which
command) lives in `settings.hooks` in `settings.nix`.

A PreToolUse entry on `WebSearch`, inline in `settings.nix`, blocks the
built-in search (exit 2) and tells the agent to use the `searxng` MCP
server's `searxng_web_search` instead. Subagents hit the same hook. Codex
turns its built-in search off (`../codex/default.nix`) and pi blocks
pi-web-access's search tools (`../pi/extensions/searxng-search.ts`).

`adhd-final-response.sh` (UserPromptSubmit) prints the i-have-adhd reminder
when the plugin's opt-in flag exists, and stays silent otherwise.

`clokkr-gate.mjs` (UserPromptSubmit, Stop) comes from `../clokkr-gate/`,
which links and registers it on hosts with Clokkr: root agents log their
client-repo turns to Clokkr. See `../clokkr-gate/CLAUDE.md`.

`context-mode-cache-heal.mjs` is a vendored copy of the script context-mode
deploys for its marketplace install. context-mode rewrites the hook's command
in `settings.json` to the quoted bare-script form on every boot, so
`settings.nix` declares that exact string. Any other spelling makes the array
union append a fresh copy on each rebuild.

## Shared with pi and Codex

pi reads the same `CLAUDE.md`, rules, skills and agents through its
claude-bridge extension (`../pi/`). A change here reaches pi after the same
rebuild. Skills and agents that need Claude-only features (hooks, MCP tools)
are excluded or tuned in `../pi/default.nix`.

Codex gets the MCP servers, rules, agents and `block-rm-rf.sh` from this
folder through `../codex/`, which converts them at build time. Skills are
listed one by one in `../codex/skills.nix`, so add a new skill there too
(Matt Pocock's come from `mattpocock-skills.nix` instead).

GPUI knowledge is shared the same way. `skills/gpui/` holds the versioned
quirk log pooled from the Concierge, Clokkr and Numero apps: a short
`SKILL.md` index and one reference file per area. `rules/rust/gpui.md` is a
path-scoped rule (`*.rs`, `Cargo.toml`) that tells Claude Code and pi to load
that skill in a GPUI crate. Codex has no path-scoped rules, and
`../codex/instructions.nix` leaves `rules/rust/` out, so Codex finds the skill
by its description. Add new generic quirks to the matching reference file,
with the versions they were seen on.

## Notes for future Claude sessions

If you're editing Claude Code config: edit the nix module, not `~/.claude/`.
If a setting doesn't survive a rebuild, that's the signal to declare it
declaratively rather than tweak it imperatively.
