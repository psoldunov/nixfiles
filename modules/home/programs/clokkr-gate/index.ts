/**
 * clokkr-gate for pi: the turn logging Claude Code and Codex get from
 * clokkr-gate.mjs as hook commands, from the same functions. ./default.nix
 * links this folder to pi's extensions/clokkr-gate/, and pi loads this file.
 *
 * pi has no blocking stop, so a turn that still needs logging gets a follow-up
 * message instead, which starts the run that logs it.
 */

import type { ExtensionAPI } from '@earendil-works/pi-coding-agent'
// @ts-ignore: a plain ES module without types.
import { isRoot, loadConfig, onPrompt, stop } from './clokkr-gate.mjs'

type Turn = { start: number; prompt: string; end?: number; asked?: boolean }

const textOf = (message: unknown): string => {
  const content = (message as { role?: string; content?: unknown }).content
  if (typeof content === 'string') return content
  return Array.isArray(content) ? content.map(part => (part?.type === 'text' ? part.text : '')).join('\n') : ''
}

const lastAnswer = (messages: readonly unknown[]): string =>
  textOf(messages.findLast(message => (message as { role?: string }).role === 'assistant') ?? {})

export default function clokkrGate(pi: ExtensionAPI) {
  const config = loadConfig()
  if (!config || !isRoot({})) return
  let turn: Turn | undefined

  pi.on('before_agent_start', event => {
    if (event.messageType === 'user') turn = onPrompt(turn, Date.now(), event.prompt)
  })

  pi.on('agent_end', async (event, ctx) => {
    try {
      const out = stop(config, turn, Date.now(), ctx.cwd, lastAnswer(event.messages))
      turn = out.state
      if (out.block) await pi.sendUserMessage(out.block)
    } catch (error) {
      // Time tracking must never wedge a session: report and drop the turn.
      turn = undefined
      if (ctx.hasUI) ctx.ui.notify(`clokkr-gate: ${String(error)}`, 'warning')
    }
  })
}
