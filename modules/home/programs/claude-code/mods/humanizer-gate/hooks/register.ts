import type { EngineInterface, Register, SessionMessage, ToolCallInput } from 'claude-code'
import { classify, gateMessage, isHumanizerSkill, type Target } from './policy.ts'

// The loops (the main conversation, each subagent) whose context holds the skill.
const LOADED = { plugin: 'humanizer-gate', key: 'loaded' } as const
const MAIN = 'main'
// tool.call fields that are not the tool's own arguments.
const ENVELOPE = new Set(['tool', 'tool_use_id', 'agentId'])

const loopOf = (agentId: string | undefined): string => agentId ?? MAIN

const loadedLoops = async ($: EngineInterface): Promise<readonly string[]> => (await $.state.get(LOADED)).value ?? []

const setLoaded = async ($: EngineInterface, loop: string, isLoaded: boolean): Promise<void> => {
  const loops = await loadedLoops($)
  if (loops.includes(loop) === isLoaded) return
  await $.state.set(LOADED, isLoaded ? [...loops, loop] : loops.filter(held => held !== loop))
}

const argumentsOf = (e: ToolCallInput): Record<string, unknown> =>
  Object.fromEntries(Object.entries(e).filter(([key]) => !ENVELOPE.has(key)))

const targetOf = (e: ToolCallInput): Target | undefined => {
  if (e.tool === 'Write') return { kind: 'write', path: e.file_path, text: e.content, partial: false }
  if (e.tool === 'Edit') return { kind: 'write', path: e.file_path, text: e.new_string, partial: true }
  if (e.tool === 'Bash') return { kind: 'shell', command: e.command }
  const tool = String(e.tool)
  return tool.startsWith('mcp__') ? { kind: 'tool', name: tool, input: argumentsOf(e) } : undefined
}

// Whether a compaction kept the Skill call that loaded the humanizer.
const keepsHumanizer = (messages: readonly SessionMessage[]): boolean =>
  messages.some(message =>
    message.toolUses.some(use => use.tool === 'Skill' && isHumanizerSkill(String(use.input.skill ?? ''))),
  )

export const register: Register = on => {
  // Skill tool calls in flight. The skill.prompt they raise belongs to their own
  // loop, which the Skill hook records. skill.prompt carries no agentId, so any
  // other one (the person's /humanizer, a preload) counts for the main loop.
  let skillCalls = 0

  on('tool.call', async ($, e, next) => {
    const target = targetOf(e)
    const verdict = target === undefined ? undefined : classify(target)
    if (verdict === undefined || !verdict.gated) return next(e)
    if ((await loadedLoops($)).includes(loopOf(e.agentId))) return next(e)
    return { deny: gateMessage(verdict.what, 'claude') }
  }).catch(($, e, next) => next(e)) // A quality gate, not a security one: fail open.

  on('tool.call', { tool: 'Skill' }, async ($, e, next) => {
    if (!isHumanizerSkill(e.skill)) return next(e)
    skillCalls += 1
    try {
      const ran = await next(e)
      if (ran.deny === undefined && ran.isError !== true) await setLoaded($, loopOf(e.agentId), true)
      return ran
    } finally {
      skillCalls -= 1
    }
  }).catch(($, e, next) => next(e))

  on('skill.prompt', async ($, e, next) => {
    const prompt = await next(e)
    if (skillCalls === 0 && isHumanizerSkill(e.skill)) await setLoaded($, MAIN, true)
    return prompt
  })

  // A compaction that summarized the skill away re-arms the gate for that loop.
  on('session.compact', async ($, e, next) => {
    const compacted = await next(e)
    if (e.trigger === 'precompute' || compacted.messages === undefined) return compacted
    if (!keepsHumanizer(compacted.messages)) await setLoaded($, loopOf(e.agentId), false)
    return compacted
  }).catch(($, e, next) => next(e))

  on('session.end', async ($, e, next) => {
    if (e.reason === 'clear') await $.state.set(LOADED, [])
    return next(e)
  })
}
