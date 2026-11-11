/**
 * nix-owned-paths for Codex: refuses an apply_patch that adds, updates, moves
 * or deletes a file whose real path is under /nix/store, as hooks/register.ts
 * does for Claude Code's Edit and Write. ../../../codex/default.nix runs it
 * with Node on PreToolUse `^apply_patch$`.
 *
 * Erasable TypeScript only: Node 24 runs it as it is.
 */

import { readFileSync, realpathSync } from 'node:fs'
import { dirname, resolve } from 'node:path'

const NIX_STORE = '/nix/store/'
const HEADER = /^\*\*\* (?:Add File|Update File|Delete File|Move to): (.+)$/gm

/** Every path an apply_patch envelope touches, resolved against `cwd`. */
export const patchPaths = (patch: string, cwd: string): string[] =>
  [...patch.matchAll(HEADER)].map(match => resolve(cwd, (match[1] ?? '').trim()))

/**
 * Where the path lands, every link followed. A file that does not exist yet
 * lands wherever its nearest existing parent does, so a new file under a
 * linked directory is caught too. Undefined when nothing on the way resolves.
 */
export function landing(path: string, realpath: (path: string) => string = realpathSync): string | undefined {
  for (let at = path; ; at = dirname(at)) {
    try {
      return realpath(at)
    } catch {
      if (dirname(at) === at) return undefined
    }
  }
}

/** The refusal for the first Nix-owned path the patch touches, else undefined. */
export function refusal(patch: string, cwd: string, realpath?: (path: string) => string): string | undefined {
  for (const path of patchPaths(patch, cwd)) {
    const real = landing(path, realpath)
    if (real !== undefined && real.startsWith(NIX_STORE)) {
      return `${path} is managed by Nix (it resolves to ${real}). Edit its source in ~/.nixfiles (or bump the flake input it comes from), then run rebuild_system. ~/.codex/ comes from modules/home/programs/codex/, ~/.claude/ from modules/home/programs/claude-code/.`
    }
  }
  return undefined
}

if (import.meta.main) {
  try {
    const input = JSON.parse(readFileSync(0, 'utf8')) as { cwd?: unknown; tool_input?: { command?: unknown } }
    const patch = typeof input.tool_input?.command === 'string' ? input.tool_input.command : ''
    const deny = refusal(patch, typeof input.cwd === 'string' ? input.cwd : process.cwd())
    if (deny !== undefined) {
      process.stdout.write(
        JSON.stringify({
          hookSpecificOutput: { hookEventName: 'PreToolUse', permissionDecision: 'deny', permissionDecisionReason: deny },
        }),
      )
    }
  } catch {
    // Leave the call to Codex; a write into the store fails on its own.
  }
}
