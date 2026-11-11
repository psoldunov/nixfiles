/**
 * humanizer-gate for pi: the gate hooks/register.ts applies in Claude Code,
 * from the same policy. modules/home/programs/pi/default.nix links this folder
 * to ~/.pi/agent/extensions/humanizer-gate/, and pi loads this file as its entry.
 *
 * A write, edit, shell command or tool call that produces human-facing text is
 * blocked until the humanizer skill is in the model's context. The context is
 * read at the moment of the call, so a compaction that summarized the skill
 * away re-arms the gate with no state of its own.
 */

import type { ExtensionAPI, ExtensionContext, ToolCallEvent } from '@earendil-works/pi-coding-agent'
import { classify, contextHasHumanizer, gateMessage, type Target } from './hooks/policy.ts'

const text = (value: unknown): string => (typeof value === 'string' ? value : '')

// pi-mcp-adapter's `mcp` gateway and `mcp__<server>` namespace proxies, whose
// `{ tool, args }` name the MCP tool they run.
const ADAPTER_PROXY = /^mcp(__[\w-]+)?$/

/** The adapter's `args`, an object or a JSON string; a string that does not parse stays as it is. */
function adapterArgs(args: unknown): unknown {
  if (typeof args !== 'string') return args
  try {
    return JSON.parse(args)
  } catch {
    return args
  }
}

/** pi's write, edit and bash arguments as a policy target; an adapter proxy call as the MCP tool it runs; any other tool as itself. */
export function targetOf(event: Pick<ToolCallEvent, 'toolName' | 'input'>): Target {
  const input = event.input as Record<string, unknown>
  const path = text(input.path).replace(/^@/, '')
  // Only the proxy's own top level is unwrapped: nested values are arguments, never calls.
  if (ADAPTER_PROXY.test(event.toolName) && text(input.tool) !== '') {
    return { kind: 'tool', name: text(input.tool), input: adapterArgs(input.args) }
  }
  switch (event.toolName) {
    case 'write':
      return { kind: 'write', path, text: text(input.content), partial: false }
    case 'edit': {
      const edits = Array.isArray(input.edits) ? (input.edits as { newText?: unknown }[]) : []
      return { kind: 'write', path, text: edits.map(edit => text(edit.newText)).join('\n'), partial: true }
    }
    case 'bash':
      return { kind: 'shell', command: text(input.command) }
    default:
      return { kind: 'tool', name: event.toolName, input }
  }
}

/** The compaction-aware entries the model currently sees, as message-like objects. */
function contextMessages(ctx: ExtensionContext): unknown[] {
  return ctx.sessionManager.buildContextEntries().map(entry => ('message' in entry ? entry.message : entry))
}

export default function humanizerGate(pi: ExtensionAPI) {
  pi.on('tool_call', (event, ctx) => {
    try {
      const verdict = classify(targetOf(event))
      if (!verdict.gated || contextHasHumanizer(contextMessages(ctx))) return undefined
      return { block: true, reason: gateMessage(verdict.what, 'pi') }
    } catch (error) {
      // A quality gate, not a security one: pi blocks a call whose handler
      // throws, so report the failure and let the call through.
      if (ctx.hasUI) ctx.ui.notify(`humanizer-gate: check failed, call let through (${String(error)})`, 'warning')
      return undefined
    }
  })
}
