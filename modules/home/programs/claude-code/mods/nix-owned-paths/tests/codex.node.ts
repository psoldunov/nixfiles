/**
 * The Codex hook (../codex.ts) under plain Node:
 *   node --test modules/home/programs/claude-code/mods/nix-owned-paths/tests/codex.node.ts
 * Named outside `*.test.ts` so `claude plugin test` leaves it to Node.
 */

import assert from 'node:assert/strict'
import { test } from 'node:test'
import { patchPaths, refusal } from '../codex.ts'

// A fake filesystem: ~/.codex/AGENTS.md and ~/.codex/skills/tdd link into the store.
const LINKS: Record<string, string> = {
  '/home/u': '/home/u',
  '/home/u/.codex': '/home/u/.codex',
  '/home/u/.codex/AGENTS.md': '/nix/store/abc-hm-files/.codex/AGENTS.md',
  '/home/u/.codex/skills': '/home/u/.codex/skills',
  '/home/u/.codex/skills/tdd': '/nix/store/def-tdd',
  '/home/u/repo': '/home/u/repo',
  '/': '/',
}
const realpath = (path: string): string => {
  const real = LINKS[path]
  if (real === undefined) throw new Error(`ENOENT: ${path}`)
  return real
}

const patch = (...headers: string[]): string => ['*** Begin Patch', ...headers, '*** End Patch'].join('\n')

test('reads every path a patch touches', () => {
  assert.deepEqual(
    patchPaths(patch('*** Add File: a.md', '+x', '*** Update File: b.md', '*** Move to: c.md', '*** Delete File: /abs/d.md'), '/repo'),
    ['/repo/a.md', '/repo/b.md', '/repo/c.md', '/abs/d.md'],
  )
})

test('refuses a file that resolves into the store', () => {
  const deny = refusal(patch('*** Update File: AGENTS.md'), '/home/u/.codex', realpath)
  assert.match(deny ?? '', /AGENTS\.md is managed by Nix \(it resolves to \/nix\/store\/abc-hm-files/)
})

test('refuses a new file under a linked directory', () => {
  assert.ok(refusal(patch('*** Add File: /home/u/.codex/skills/tdd/extra.md', '+x'), '/', realpath))
})

test('lets ordinary files through', () => {
  assert.equal(refusal(patch('*** Add File: notes.md', '+x', '*** Update File: src/a.ts'), '/home/u/repo', realpath), undefined)
})
