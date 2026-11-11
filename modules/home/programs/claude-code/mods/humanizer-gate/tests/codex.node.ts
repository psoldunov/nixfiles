/**
 * The Codex hook (../codex.ts) under plain Node:
 *   node --test modules/home/programs/claude-code/mods/humanizer-gate/tests/codex.node.ts
 * Named outside `*.test.ts` so `claude plugin test` leaves it to Node.
 */

import assert from 'node:assert/strict'
import { test } from 'node:test'
import { decide, patchTargets, transcriptHasHumanizer, type HookInput } from '../codex.ts'

const PROSE = 'This guide walks through installing the tool and wiring it into an existing project. '.repeat(4)

const addReadme = (cwd = '/repo'): HookInput => ({
  cwd,
  tool_name: 'apply_patch',
  tool_input: { command: `*** Begin Patch\n*** Add File: README.md\n+# Tool\n+${PROSE}\n*** End Patch\n` },
  transcript_path: '/t.jsonl',
})

const jsonl = (...lines: object[]): string => lines.map(line => JSON.stringify(line)).join('\n')

const SKILL_LISTING = {
  type: 'response_item',
  payload: { type: 'message', role: 'developer', content: [{ type: 'input_text', text: '- humanizer: Rewrite text (file: r1/humanizer/SKILL.md)' }] },
}
const AGENTS_MD = {
  type: 'response_item',
  payload: { type: 'message', role: 'user', content: [{ type: 'input_text', text: 'Before you write human-facing text, invoke `$humanizer`.' }] },
}
const SKILL_READ = {
  type: 'response_item',
  payload: { type: 'custom_tool_call', name: 'exec', input: 'await tools.exec_command({cmd:"cat ~/.codex/skills/humanizer/SKILL.md"})' },
}
const SHELL_READ = {
  type: 'response_item',
  payload: { type: 'function_call', name: 'exec_command', arguments: '{"cmd":"sed -n 1,400p /home/u/.codex/skills/humanizer/SKILL.md"}' },
}
const USER_ASKS = { type: 'event_msg', payload: { type: 'user_message', message: 'Rewrite the README with $humanizer' } }
const COMPACTED = { type: 'compacted', payload: { message: 'summary' } }

const denies = (input: HookInput, transcript: string): boolean => decide(input, () => transcript) !== undefined

test('reads the files and added lines out of an apply_patch envelope', () => {
  const patch = [
    '*** Begin Patch',
    '*** Add File: docs/new.md',
    '+first',
    '*** Update File: old.md',
    '*** Move to: docs/moved.md',
    '@@',
    '-gone',
    '+kept',
    '*** End of File',
    '+after the marker',
    '*** Delete File: stale.md',
    '+not part of any file',
    '*** End Patch',
  ].join('\n')
  assert.deepEqual(patchTargets(patch, '/repo'), [
    { kind: 'write', path: '/repo/docs/new.md', text: 'first', partial: false },
    { kind: 'write', path: '/repo/docs/moved.md', text: 'kept\nafter the marker', partial: true },
  ])
})

test('blocks a README patch until the skill is read', () => {
  const reply = decide(addReadme(), () => '')
  assert.ok(reply, 'blocks with an empty transcript')
  const parsed = JSON.parse(reply)
  assert.equal(parsed.hookSpecificOutput.permissionDecision, 'deny')
  assert.match(parsed.hookSpecificOutput.permissionDecisionReason, /README\.md.*cat/)
  assert.equal(denies(addReadme(), jsonl(SKILL_READ)), false)
  assert.equal(denies(addReadme(), jsonl(SHELL_READ)), false)
})

test('the skill listing and AGENTS.md do not count as loading it', () => {
  assert.equal(transcriptHasHumanizer(jsonl(SKILL_LISTING, AGENTS_MD)), false)
  assert.equal(denies(addReadme(), jsonl(SKILL_LISTING, AGENTS_MD)), true)
})

test("the user's own $humanizer prompt counts", () => {
  assert.equal(denies(addReadme(), jsonl(USER_ASKS)), false)
})

test('a compaction re-arms the gate', () => {
  assert.equal(denies(addReadme(), jsonl(SKILL_READ, COMPACTED)), true)
  assert.equal(denies(addReadme(), jsonl(SKILL_READ, COMPACTED, SHELL_READ)), false)
})

test('gates gh posts and sending MCP tools, passes code and agent files', () => {
  const transcript = ''
  assert.equal(denies({ tool_name: 'Bash', tool_input: { command: 'gh pr create --fill' }, transcript_path: '/t' }, transcript), true)
  assert.equal(
    denies({ tool_name: 'mcp__claude_ai_Slack__slack_send_message', tool_input: { text: 'hi' }, transcript_path: '/t' }, transcript),
    true,
  )
  assert.equal(denies({ tool_name: 'Bash', tool_input: { command: 'git status' }, transcript_path: '/t' }, transcript), false)
  const code = { ...addReadme(), tool_input: { command: `*** Begin Patch\n*** Add File: src/a.ts\n+${PROSE}\n*** End Patch` } }
  assert.equal(denies(code, transcript), false)
  const agents = { ...addReadme(), tool_input: { command: `*** Begin Patch\n*** Add File: AGENTS.md\n+${PROSE}\n*** End Patch` } }
  assert.equal(denies(agents, transcript), false)
})

test('stays open without a transcript, and for small edits', () => {
  assert.equal(denies({ ...addReadme(), transcript_path: undefined }, ''), false)
  const typo = { ...addReadme(), tool_input: { command: '*** Begin Patch\n*** Update File: README.md\n@@\n-teh\n+the\n*** End Patch' } }
  assert.equal(denies(typo, ''), false)
})
