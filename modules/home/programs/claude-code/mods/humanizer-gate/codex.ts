/**
 * humanizer-gate for Codex: the gate hooks/register.ts applies in Claude Code,
 * from the same policy, as a Codex command hook. ../../../codex/default.nix
 * runs it with Node on PreToolUse for Bash, apply_patch and MCP tools.
 *
 * Codex hooks cannot see the model's context, so the hook reads the session
 * transcript instead. The skill counts as loaded when, since the last
 * compaction, a tool call mentions its SKILL.md or the user's own prompt names
 * `$humanizer`. As in pi, a compaction re-arms the gate with no state of its own.
 *
 * Erasable TypeScript only: Node 24 runs it as it is.
 */

import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { classify, gateMessage, type Target, type Verdict } from './hooks/policy.ts'

/** The PreToolUse fields this hook reads. */
export type HookInput = {
  cwd?: unknown
  tool_name?: unknown
  tool_input?: unknown
  transcript_path?: unknown
}

type PatchFile = { path: string; added: string[]; partial: boolean }

const ADD = '*** Add File: '
const UPDATE = '*** Update File: '
const MOVE = '*** Move to: '
// Headers that close a file section. `*** End of File` sits inside an update hunk.
const CLOSE = ['*** Delete File: ', '*** End Patch']

const text = (value: unknown): string => (typeof value === 'string' ? value : '')

/** The files an apply_patch envelope writes, each with the lines it adds, resolved against `cwd`. */
export function patchTargets(patch: string, cwd: string): Target[] {
  // Built line by line; the section being read is the one `+` lines land in.
  const files: PatchFile[] = []
  let current: PatchFile | undefined
  for (const line of patch.split('\n')) {
    if (line.startsWith(ADD) || line.startsWith(UPDATE)) {
      const partial = line.startsWith(UPDATE)
      current = { path: line.slice((partial ? UPDATE : ADD).length), added: [], partial }
      files.push(current)
    } else if (line.startsWith(MOVE) && current !== undefined) current.path = line.slice(MOVE.length)
    else if (CLOSE.some(header => line.startsWith(header))) current = undefined
    else if (line.startsWith('+') && current !== undefined) current.added.push(line.slice(1))
  }
  return files.map(file => ({
    kind: 'write' as const,
    path: resolve(cwd, file.path.trim()),
    text: file.added.join('\n'),
    partial: file.partial,
  }))
}

/** Codex's Bash, apply_patch and MCP calls as policy targets; any other tool passes. */
export function targetsOf(input: HookInput): Target[] {
  const name = text(input.tool_name)
  const args = (input.tool_input ?? {}) as Record<string, unknown>
  if (name === 'apply_patch') return patchTargets(text(args.command), text(input.cwd) || process.cwd())
  if (name === 'Bash') {
    const command = Array.isArray(args.command) ? args.command.map(text).join(' ') : text(args.command)
    return [{ kind: 'shell', command }]
  }
  return name.startsWith('mcp__') ? [{ kind: 'tool', name, input: input.tool_input }] : []
}

/** The first gated verdict among `input`'s targets, else a pass. */
export function verdictOf(input: HookInput): Verdict {
  for (const target of targetsOf(input)) {
    const verdict = classify(target)
    if (verdict.gated) return verdict
  }
  return { gated: false }
}

const SKILL_FILE = /humanizer\/SKILL\.md/
const SKILL_MENTION = /\$humanizer\b/

type Line = { type?: unknown; payload?: Record<string, unknown> }

function lineLoadsHumanizer(line: Line): boolean {
  const payload = line.payload ?? {}
  if (line.type === 'event_msg') return payload.type === 'user_message' && SKILL_MENTION.test(text(payload.message))
  if (line.type !== 'response_item') return false
  switch (payload.type) {
    case 'function_call':
      return SKILL_FILE.test(text(payload.arguments))
    case 'custom_tool_call':
      return SKILL_FILE.test(text(payload.input))
    case 'local_shell_call':
      return SKILL_FILE.test(JSON.stringify(payload.action ?? null))
    default:
      return false
  }
}

/**
 * Whether a Codex rollout (JSONL) holds the skill after its last compaction.
 * The skill listing and AGENTS.md name it too, but as context messages, which
 * do not count: only a tool call that reads it, or the user's own prompt.
 */
export function transcriptHasHumanizer(jsonl: string): boolean {
  const lines = jsonl.split('\n')
  const compacted = lines.findLastIndex(line => line.includes('"type":"compacted"'))
  return lines.slice(compacted + 1).some(line => {
    if (!line.includes('humanizer')) return false
    try {
      return lineLoadsHumanizer(JSON.parse(line) as Line)
    } catch {
      return false
    }
  })
}

/** The PreToolUse reply that blocks a call, or undefined to let it run. */
export function decide(input: HookInput, readTranscript: (path: string) => string): string | undefined {
  const verdict = verdictOf(input)
  if (!verdict.gated) return undefined
  const path = text(input.transcript_path)
  // No transcript to read: the gate cannot tell, so it stays open.
  if (path === '') return undefined
  if (transcriptHasHumanizer(readTranscript(path))) return undefined
  return JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'deny',
      permissionDecisionReason: gateMessage(verdict.what, 'codex'),
    },
  })
}

if (import.meta.main) {
  try {
    const reply = decide(JSON.parse(readFileSync(0, 'utf8')) as HookInput, path => readFileSync(path, 'utf8'))
    if (reply !== undefined) process.stdout.write(reply)
  } catch {
    // A quality gate, not a security one: on any failure the call goes through.
  }
}
