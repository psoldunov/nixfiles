import type { On } from 'claude-code'
import { expect, test } from 'claude-code/testing'

const README = { tool: 'Write', file_path: '/repo/README.md', content: '# Project' } as const
const LOAD = { tool: 'Skill', skill: 'humanizer' } as const

type ToolUse = { tool: string; input: Record<string, unknown> }

const SKILL_CALL: ToolUse = { tool: 'Skill', input: { skill: 'humanizer' } }

// A transcript: a summary line, then the given tool calls.
const transcript = (toolUses: readonly ToolUse[]) => [
  { role: 'user' as const, text: 'Summary of the conversation so far.', toolUses: [] },
  ...(toolUses.length === 0
    ? []
    : [{ role: 'assistant' as const, text: '', toolUses: toolUses.map((use, i) => ({ ...use, tool_use_id: `t${i}` })) }]),
]

// The engine beneath the plugin: every tool runs, every skill expands, and a
// compaction leaves its summary plus the tool calls in `kept`.
const world = (on: On, kept: readonly ToolUse[] = []) => {
  on('tool.call', () => ({ result: 'ran' }))
  on('skill.prompt', () => ({ text: 'humanizer body' }))
  on('session.compact', () => ({ messages: transcript(kept) }))
}

const compact = { trigger: 'manual', messages: transcript([SKILL_CALL]) } as const

test('refuses a README write before the skill is loaded', async ($, on) => {
  world(on)
  const ran = await $.tool.call(README)
  expect(ran.deny).toContain('humanizer-gate')
  expect(ran.deny).toContain('/repo/README.md')
})

test('lets the write through once the Skill tool loaded humanizer', async ($, on) => {
  world(on)
  await $.tool.call(LOAD)
  const ran = await $.tool.call(README)
  expect(ran.deny).toBeUndefined()
  expect(ran.result).toBe('ran')
})

test('a /humanizer typed by the person counts for the main conversation', async ($, on) => {
  world(on)
  await $.skill.prompt({ skill: 'humanizer', text: '' })
  const ran = await $.tool.call(README)
  expect(ran.deny).toBeUndefined()
})

test('another skill does not open the gate', async ($, on) => {
  world(on)
  await $.tool.call({ tool: 'Skill', skill: 'caveman' })
  const ran = await $.tool.call(README)
  expect(ran.deny).toContain('humanizer-gate')
})

test('code and agent-facing files are never gated', async ($, on) => {
  world(on)
  expect((await $.tool.call({ tool: 'Write', file_path: '/repo/src/a.ts', content: 'x' })).deny).toBeUndefined()
  expect((await $.tool.call({ tool: 'Write', file_path: '/repo/CLAUDE.md', content: 'x' })).deny).toBeUndefined()
  expect((await $.tool.call({ tool: 'Bash', command: 'git commit -m "feat: x"' })).deny).toBeUndefined()
})

test('a Slack send is gated, a Linear state change is not', async ($, on) => {
  world(on)
  const send = await $.tool.call({ tool: 'mcp__claude_ai_Slack__slack_send_message', channel_id: 'C1', message: 'hi' })
  expect(send.deny).toContain('slack_send_message')
  const state = await $.tool.call({ tool: 'mcp__plugin_hm_linear-swiss-cheese__save_issue', id: 'ABC-1', state: 'Done' })
  expect(state.deny).toBeUndefined()
})

test('a compaction that dropped the skill re-arms the gate', async ($, on) => {
  world(on)
  await $.tool.call(LOAD)
  await $.session.compact(compact)
  const ran = await $.tool.call(README)
  expect(ran.deny).toContain('humanizer-gate')
})

test('a compaction that kept the Skill call leaves the gate open', async ($, on) => {
  world(on, [SKILL_CALL])
  await $.tool.call(LOAD)
  await $.session.compact(compact)
  const ran = await $.tool.call(README)
  expect(ran.deny).toBeUndefined()
})

// The engine carries agentId on a subagent's calls; $.tool.call's types leave it out.
const inWorker = <T extends object>(input: T): T => ({ ...input, agentId: 'worker' })

test('each subagent loads the skill for itself', async ($, on) => {
  world(on)
  await $.tool.call(LOAD)
  expect((await $.tool.call(inWorker(README))).deny).toContain('humanizer-gate')
  await $.tool.call(inWorker(LOAD))
  expect((await $.tool.call(inWorker(README))).deny).toBeUndefined()
})
