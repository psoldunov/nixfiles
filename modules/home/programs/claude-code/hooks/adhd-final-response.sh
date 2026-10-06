#!/usr/bin/env bash
# UserPromptSubmit hook: keep the i-have-adhd ruleset in force for the answer
# each turn ends on. The plugin's own SessionStart hook injects the full
# ruleset once per session; this short reminder rides every prompt, so the
# shape holds deep into a long session and after tool-heavy turns.
# It follows the plugin's own opt-in flag, so one toggle covers both hooks.
set -uo pipefail

flag="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.i-have-adhd-always"
[ -f "$flag" ] || exit 0

cat <<'EOF'
ADHD MODE ACTIVE (i-have-adhd). The final message of this turn, the answer the reader acts on, follows the i-have-adhd ruleset from session start:
1. First line is the next action or the answer itself. No preamble, recap or closer.
2. Multi-step work is a numbered list, one bounded action per step, fewest steps that work.
3. Restate where the work stands (step N of M, what now works, concretely).
4. Stay on one topic. Offer a side issue as one separate question at the end.
5. Time estimates in concrete units. Lists capped at 5 visible items per group.
6. When anything is left open, end with ONE concrete next action doable in under two minutes.
Interim status lines between tool calls stay short; these rules shape the final message. Caveman, when active, sets the wording; this sets the structure and takes precedence where the two conflict. Off only after the reader says "stop adhd mode" or "normal mode" in this session.
EOF
