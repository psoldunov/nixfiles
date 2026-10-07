# Human-Facing Text

Text written for someone other than the user in this chat goes through the
`humanizer` skill before it is written or sent.

## What counts

- Docs, READMEs, changelogs, contributing guides, release notes
- Website, landing page, UI and CMS copy, including locale files
- Emails, Slack messages and anything else drafted for the user to send
- Pull request descriptions, GitHub issues and their comments
- Linear issues, comments, documents and status updates

## What does not

- Replies to the user. Caveman and i-have-adhd keep shaping those.
- Commit messages, code comments and docstrings
- Agent-facing files: `CLAUDE.md`, `AGENTS.md`, rules, skills, agent prompts,
  plans and memory

## How

1. Load the skill before writing: the Skill tool (`humanizer`) in Claude Code,
   or its `SKILL.md` from the skill listing in pi.
2. Draft the text.
3. Run the skill's pattern scan and its final anti-AI pass on the draft.
4. Write or send the result. A draft shown to the user for sending is the
   humanized version.

## Voice

- Match the artifact's register. Technical docs stay plain and precise: skip
  the skill's advice to add opinions, humor or first person.
- Text sent in the user's name sounds like the user. Calibrate from a sample
  of their own writing when one is at hand: the thread being replied to, their
  earlier messages, or the docs already in the repository.

## The gate

The `humanizer-gate` mod (Claude Code) and its pi extension refuse the first
human-facing write or send of a session, and the first one after a compaction,
until the skill is loaded. Load it and retry. Do not route around the gate
with shell redirection or another tool.
