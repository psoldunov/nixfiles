---
name: council
description: Use when the user says "council". Two delegates on different providers, Claude and Codex (GPT), review or advise in parallel, and the loop repeats until both are satisfied.
---

# Council

The council has two members, one per provider: a Claude member and a Codex
member. Each gets the request and its context in parallel, at high reasoning
effort. You judge what they say, make the changes you agree with, and run
fresh rounds until both are satisfied.

## 1. Prepare

Before a review, address outstanding PR comments, fix known issues, and run
the relevant checks. Give the council the updated implementation and finish
known fixes before it starts. If the user wants to discard the implementation
and explore new ideas, skip fixes to code being replaced.

## 2. Seat the members

Members the user names win. Otherwise seat the latest flagship of each
provider:

- Claude: the `opus` alias (the latest Opus), effort `high`.
- Codex: the latest Sol, reasoning effort `high`. Resolve its id, never
  hardcode one:

  ```bash
  sol=$(jq -r '[.models[] | select(.visibility == "list" and (.slug | test("-sol$")))] | sort_by(.priority) | .[0].slug // empty' ~/.codex/models_cache.json 2>/dev/null)
  # No Codex cache (the pi fallback): the newest Sol pi lists.
  [ -n "$sol" ] || sol=$(pi --list-models 2>/dev/null | awk '$1 == "openai" && $2 ~ /-sol$/ {print $2}' | sort -V | tail -n 1)
  ```

  An empty `$sol` after both lines means the Codex seat is unreachable.

Seat a fresh Claude member even when you are Claude yourself: it reads the
change without your context. If a member cannot be reached on any route
below, or a named member is unavailable, report that and stop. The council
keeps one provider per seat, so a missing seat stays empty.

Pick each member's route by where you run:

| You run in | Claude member | Codex member |
| --- | --- | --- |
| Ensemblr | child conversation | `codex exec` |
| Claude Code with the Agent tool | Agent tool, `model: "opus"` | `codex exec` |
| Codex, pi, a plain shell | `claude -p` | `codex exec` |

In Ensemblr, any member whose runtime appears in `allowedRuntimes` from
`ensemblr_list_models` runs as a child conversation: model `opus` (or the
named member's id from that list), `thinkingLevel: "high"`, and the brief as
its prompt. Every other member uses its CLI. When a native route is refused
(an Ensemblr leaf cannot spawn children), the Claude member uses `claude -p`.
The Codex member falls back to pi when `codex` is missing or logged out
(`codex login status`).

```bash
run=$(mktemp -d "${TMPDIR:-/tmp}/council.XXXXXX")

# Codex member
env -u OPENAI_API_KEY ENSEMBLR_CONTROL_DEPTH=1 codex exec -C "$PWD" -s read-only --ephemeral \
  --ignore-user-config -c 'project_doc_fallback_filenames=["CLAUDE.md"]' -c web_search=disabled \
  -m "$sol" -c model_reasoning_effort=high -o "$run/codex-r1.md" - < "$run/brief-r1.md"

# Codex member through pi (fallback)
ENSEMBLR_CONTROL_DEPTH=1 pi -p --no-session --model "openai/$sol" --thinking high \
  --tools read,grep,find,ls --no-mcp < "$run/brief-r1.md" > "$run/codex-r1.md"

# Claude member through the CLI
ENSEMBLR_CONTROL_DEPTH=1 claude -p --model opus --effort high --tools Read,Grep,Glob \
  --strict-mcp-config --no-session-persistence < "$run/brief-r1.md" > "$run/claude-r1.md"
```

- `env -u OPENAI_API_KEY` keeps Codex on the ChatGPT plan, off the metered API.
- `ENSEMBLR_CONTROL_DEPTH=1` marks a CLI member as a sub-agent, so clokkr-gate
  logs only your turn on client repos, not the member's on top of it.
- `--ignore-user-config` skips `~/.codex/config.toml`, and with it every MCP
  server, plugin and hook; the login still works. The two `-c` after it put
  back what that file normally sets: CLAUDE.md loading, and built-in web
  search off.
- `--strict-mcp-config` drops MCP servers. With them loaded, the tool
  definitions push `claude -p` past its 1M-token prompt limit.
- The CLI members are read-only by construction: a read-only sandbox or a
  read-only tool allowlist, and no MCP servers (whose tools can write to
  Linear, mail and the like). An Agent-tool or Ensemblr member shares your
  checkout and keeps its tools, so it stays read-only through its brief alone.
- A high-effort round takes several minutes. Start the CLI members in the
  background first, then any native member, then wait for every member.
  Leave the scoped files alone until all of them reply. A timeout, an error
  or an empty reply is a failed round, never an approval.

## 3. Brief them

Write the change to `$run/change.diff`: `git diff <base>` from the merge base
with the target branch to the working tree. Append each untracked file with
`git diff --no-index /dev/null <file>` (exit 1 there means the file differs,
which is expected). Send the brief on stdin to CLI members and as the prompt
to native ones, with the diff pasted at its end, so no member needs access
outside the repo.

Give each member its id prefix (`C` for Claude, `X` for Codex) so ledger ids
stay unique. For a code review, use this brief:

```
You sit on a two-member council reviewing a change. Work read only: read files,
and run read-only commands if you have a shell. Edit nothing, commit nothing,
comment on no PR, run no builds or tests, start no subagents. The diff is at
the end of this brief.
Repo: <abs path>   Base: <sha>   Round: <n>   Your id prefix: <C|X>
Intent: <1-2 sentences>
Out of scope: <list>
Checks already run: <command: result, one per line>
Read the surrounding code. Find bugs, broken callers and mismatches with the
intent. Report style only where it hides a bug. Hold the change to the
smallest one that meets the intent, and flag code, tests or guards the intent
does not need.
Severity: blocker = the intended case is wrong; should = a real bug callers
will hit; nit = everything else.
Reply in exactly this shape:
SCORE: <0-10>/10
VERDICT: APPROVE | CHANGES
<id> [blocker|should|nit] <file>:<line> <claim>. Fix: <suggestion>

<diff>
```

For a UI design review or a design climb, members score screenshots, not a
diff. Build the pack in `$run/pack/`:

- Screenshots of the app under review and of the reference apps the user
  named, each at most 1568 px on its long edge (`magick mogrify -resize
  '1568x1568>' "$run"/pack/app/*.png "$run"/pack/refs/*/*.png`). Larger
  images get downscaled on the member's side, and a downscaled screenshot
  can fake clipping.
- The same scenes, sizes and themes every round of a climb. A changed pack
  makes scores incomparable: score the old build on the new pack first.
- `app/<scene>-<size>-<theme>.png` and `refs/<product>/<screen>-<theme>.png`.

Never tell a member the target score, earlier rounds' scores or which change
is new. Members who know the target drift toward it, references included.
Use this brief:

```
You sit on a two-member design council. Work read only: look at the images
and read files, edit nothing, run nothing, start no subagents.
Pack: <abs path>   Round: <n>   Your id prefix: <C|X>
The app: <1-2 sentences: what it is, who uses it, for what>
References: <product: one line each>
Fixed by the owner, do not score against them: <list>
Read every image before you score. The data is a fixture: score layout,
truncation and hierarchy, never the wording of made-up titles or paths.
Score the app and each reference from 1 to 10 in each category. 10 is the
best desktop app you know for this kind of work; 7 is solid but clearly
behind the best.
Categories: <list>
Then list what holds each of the app's categories below 10, and the five
fixes that would raise its scores most, most important first. Each fix names
the scene, size and theme, what is wrong, and the change. "The sidebar's
time label competes with the title in task-dark; drop it to the muted
token" is useful; "improve hierarchy" is not.
Reply in exactly this shape:
| Category | App | <reference> | ... |
<id> [fix] <scene> <size> <theme>: <problem>. Fix: <change>
```

Before you act on a clipping or blur finding, open the image at 1:1.

For feedback, a design question or any other request, send the request, the
context and the same read-only line, and ask for a direct answer with no score.

## 4. Judge, fix, repeat

Check every finding and its severity yourself. Another path, a rare case or a
small cost is a nit, whatever label it came with.

- Agree: make the smallest fix. Delete or narrow before adding a helper, lock
  or option.
- Disagree: say why, with evidence (file:line, a test, command output).
- Out of scope or a nit: decline it in one line and list it as a follow-up.

Keep a ledger: id, severity, outcome (`fixed`, `disagree`, `declined`) and the
evidence. Re-run the checks after the fixes, then start a fresh round: both
members review again, with the same brief plus the ledger and the diff since
the last round. Ask them to report only on open ids and changed code, and to
mark each old id `resolved` or `still open: <reason>`. Each full review pass
by both members is one round.

Fight scope creep. Repeated rounds pull the change wider; your job is to keep
the scope where the intent put it.

Stop a code review when both members return `APPROVE` with no blocker or
should open. Stop a design climb when both members rate every category of the
app at or above the user's target and above every reference, or at the
user's round cap; the three-round limit below does not apply. A member may
sit out rounds to save usage, the cheaper one alone until it reaches the
target, but the climb stops only on a round both members scored. Re-score the
references every round; when a reference moves more than 0.5 on the same
images, report the round as noisy. Stop any other request once a round brings no recommendation you
agree to act on. Stop as stuck when an item is still disputed after two
replies, or after three rounds (five for security, auth, data loss or
concurrency while a blocker or should stays open with evidence). For a stuck
item, give both sides in two or three lines each and let the user decide.

## 5. Report

Summarize the useful findings, the disagreements and the recommended next
steps. For a code review, record each member's score per round. A member that
gives no score gets `no score`; never invent one.

If the work ends in a pull request, append this section to the end of the PR
description. Edit the description of an open PR with `gh pr edit`; post no
comment for it. Without a PR, put the same table in your final reply only.

```markdown
## Council review

Rounds: 2

| Delegate | Round 1 | Round 2 |
| --- | --- | --- |
| Claude Opus 5.5 | 7/10 | 9/10 |
| GPT-6.1-Sol | 8/10 | 10/10 |
```

Name each delegate by the model that actually ran. For a design climb, each
cell is the app's lowest category score that round (`not run` when a member
sat out), and a second table gives the last round's overall scores for the
app and each reference, per delegate.
