# Claude Code config is declarative

NixOS and home-manager own `~/.claude/`. Never hand-edit nix-managed files
there: the next rebuild overwrites them.

- Edit `~/.nixfiles/modules/home/programs/claude-code/` instead, then run
  `rebuild_system`. The `CLAUDE.md` in that folder has the full details.
- Still writable: `~/.claude/settings.json`, which each rebuild deep-merges
  the nix settings into (copy a CLI change into `settings.nix` to keep it),
  plus `projects/`, `plans/`, `plugins/cache/`, sessions, history and
  credentials.
