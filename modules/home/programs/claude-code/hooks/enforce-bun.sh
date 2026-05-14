#!/usr/bin/env bash
# PreToolUse(Bash) hook: enforce bun as the only package manager.
# Reads the Claude Code tool-call JSON from stdin and exits 2 (block) on match.
set -uo pipefail

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null) || exit 0

if printf '%s' "$command" | grep -qE '\b(npm|npx|yarn|pnpm|pnpx)\b'; then
  echo "BLOCK: Only bun is allowed as a package manager. Use bun instead of npm/yarn/pnpm." >&2
  exit 2
fi

exit 0
