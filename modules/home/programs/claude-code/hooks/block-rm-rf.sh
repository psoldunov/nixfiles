#!/usr/bin/env bash
# PreToolUse(Bash) hook: block `rm -rf` invocations.
# Reads the Claude Code tool-call JSON from stdin and exits 2 (block) on match.
set -uo pipefail

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null) || exit 0

if printf '%s' "$command" | grep -qE '\brm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)\b'; then
  echo "BLOCK: rm -rf is not allowed. Use safer alternatives like removing specific files." >&2
  exit 2
fi

exit 0
