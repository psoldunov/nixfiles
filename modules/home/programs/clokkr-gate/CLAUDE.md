# clokkr-gate

Root agents (Claude Code, Codex, pi) log the time they spend on client repos
to Clokkr, as one session per turn on the client's `Agents` task.

## How a turn is logged

1. At the prompt the hook notes the turn's start (state in
   `~/.local/state/clokkr-gate/<session>.json`; pi keeps it in memory).
2. At the first stop it reads the repo's `origin` remote and Clokkr's tasks.
   For client work it blocks the stop once and hands the agent the exact
   `add_session` values: task id, start, end. The agent writes the notes.
3. At the next stop it checks Clokkr for a session on that task starting near
   the turn's start. If there is none, it writes one itself with the CLI.

Turns under a minute, sub-agents (`ENSEMBLR_CONTROL_DEPTH`,
`PI_CLAUDE_BRIDGE_DEPTH`, a hook's `agent_id`) and non-client repos are
skipped. Any failure (Clokkr down, no remote) lets the stop through.

## Where the client map lives

In Clokkr, not nix: an `Agents` task whose notes hold a `repo: owner/name`
line (more than one line for a client with several repos). A repo whose org
is in `clientOrgs` (`default.nix`) and that no task names yet makes the agent
find or create the client's folder and `Agents` task (non-billable) and add the
`repo:` line before it logs. If the agent skips that, the session goes to
`Unsorted/Agents` with the repo in its notes. A client repo outside those orgs
(`Helix-ID/helix-next`) is mapped by adding its `repo:` line by hand.

## Files

- `clokkr-gate.mjs`: all logic, and the hook command (`node
  ~/.claude/hooks/clokkr-gate.mjs prompt|stop`, hook JSON on stdin).
- `index.ts`: pi's extension. pi has no blocking stop, so it sends a follow-up
  message instead.
- `default.nix`: on where the host declares `programs.mcp.servers.clokkr`;
  writes `~/.config/clokkr-gate/config.json` (CLI path, `clientOrgs`,
  `internalRepos`) and registers the hooks for Claude Code and Codex.

Codex asks to trust new hooks once (`/hooks`). Test with
`node --test modules/home/programs/clokkr-gate/clokkr-gate.test.mjs`.
