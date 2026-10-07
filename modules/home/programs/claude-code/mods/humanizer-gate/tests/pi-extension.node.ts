/**
 * The pi entry (../index.ts) under plain Node, with a stand-in for pi's API:
 *   node --test modules/home/programs/claude-code/mods/humanizer-gate/tests/pi-extension.node.ts
 * Named outside `*.test.ts` so `claude plugin test` leaves it to Node.
 */

import assert from 'node:assert/strict'
import { test } from 'node:test'
import humanizerGate, { targetOf } from '../index.ts'

type Handler = (event: unknown, ctx: unknown) => { block: boolean; reason: string } | undefined

const SKILL_READ = {
  type: 'message',
  message: {
    role: 'assistant',
    content: [{ type: 'toolCall', name: 'read', arguments: { path: '/home/u/.claude/skills/humanizer/SKILL.md' } }],
  },
}

/** Loads the extension against a fake pi and returns its tool_call handler. */
function load(): Handler {
  const handlers = new Map<string, Handler>()
  const pi = { on: (name: string, handler: Handler) => handlers.set(name, handler) }
  humanizerGate(pi as never)
  const handler = handlers.get('tool_call')
  assert.ok(handler, 'registers a tool_call handler')
  return handler
}

const ctxWith = (entries: unknown[]) => ({
  hasUI: false,
  sessionManager: { buildContextEntries: () => entries },
})

const README = { type: 'tool_call', toolCallId: 'c1', toolName: 'write', input: { path: 'README.md', content: '# Hi' } }

test('blocks a README write until the skill is in context', () => {
  const onToolCall = load()
  const blocked = onToolCall(README, ctxWith([]))
  assert.equal(blocked?.block, true)
  assert.match(blocked?.reason ?? '', /SKILL\.md/)
  assert.equal(onToolCall(README, ctxWith([SKILL_READ])), undefined)
})

test('a /skill:humanizer block counts as loaded', () => {
  const block = { type: 'message', message: { role: 'user', content: '<skill name="humanizer" location="/x/SKILL.md">' } }
  assert.equal(load()(README, ctxWith([block])), undefined)
})

test('code writes, small edits and git commits pass', () => {
  const onToolCall = load()
  const ctx = ctxWith([])
  assert.equal(onToolCall({ toolName: 'write', input: { path: 'src/a.ts', content: 'x' } }, ctx), undefined)
  assert.equal(onToolCall({ toolName: 'edit', input: { path: 'README.md', edits: [{ oldText: 'v1', newText: 'v2' }] } }, ctx), undefined)
  assert.equal(onToolCall({ toolName: 'bash', input: { command: 'git commit -m "feat: x"' } }, ctx), undefined)
})

test('gh pr create is blocked', () => {
  const blocked = load()({ toolName: 'bash', input: { command: 'gh pr create --body "..."' } }, ctxWith([]))
  assert.equal(blocked?.block, true)
})

test('a failing context read lets the call through', () => {
  const broken = { hasUI: false, sessionManager: { buildContextEntries: () => { throw new Error('no session') } } }
  assert.equal(load()(README, broken), undefined)
})

test('edit targets carry only the new text', () => {
  const target = targetOf({ toolName: 'edit', input: { path: '@docs/a.md', edits: [{ oldText: 'a', newText: 'b' }, { oldText: 'c', newText: 'd' }] } } as never)
  assert.deepEqual(target, { kind: 'write', path: 'docs/a.md', text: 'b\nd', partial: true })
})
