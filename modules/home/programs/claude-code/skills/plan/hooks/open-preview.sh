#!/usr/bin/env bash
set -euo pipefail

payload=$(cat)

tool_name=$(jq -r '.tool_name // ""' <<<"$payload")
[[ "$tool_name" == "Write" ]] || exit 0

file_path=$(jq -r '.tool_input.file_path // ""' <<<"$payload")
[[ "$file_path" =~ /\.claude/plans/[^/]+\.md$ ]] || exit 0

ide_cli=""
for candidate in code cursor windsurf code-insiders; do
  if command -v "$candidate" >/dev/null 2>&1; then
    ide_cli="$candidate"
    break
  fi
done
[[ -n "$ide_cli" ]] || exit 0

"$ide_cli" --reuse-window --goto "${file_path}:1" >/dev/null 2>&1 || true

[[ "$(uname)" == "Darwin" ]] || exit 0

case "$ide_cli" in
  cursor)        app_name="Cursor" ;;
  windsurf)      app_name="Windsurf" ;;
  code-insiders) app_name="Visual Studio Code - Insiders" ;;
  *)             app_name="Visual Studio Code" ;;
esac

osascript <<OSA >/dev/null 2>&1 &
tell application "$app_name" to activate
delay 0.35
tell application "System Events"
  tell process "$app_name"
    keystroke "p" using {command down, shift down}
    delay 0.15
    keystroke ">Markdown: Open Preview"
    delay 0.1
    key code 36
  end tell
end tell
OSA

disown 2>/dev/null || true
exit 0
