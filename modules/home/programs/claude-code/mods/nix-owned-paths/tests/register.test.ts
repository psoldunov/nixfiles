import type { FsStat, On } from 'claude-code'
import { expect, mock, test } from 'claude-code/testing'

const HOME = '/home/u'
const STORE_FILE = '/nix/store/abc-home-manager-files/.claude/CLAUDE.md'
const STORE_SKILL = '/nix/store/def-caveman/skills/caveman'
const SOURCE = `${HOME}/.nixfiles/modules/home/programs/claude-code/CLAUDE.md`

const stat = (realPath: string): FsStat => ({ kind: 'file', size: 1, mtimeMs: 0, isLink: true, realPath })

// The file system beneath the plugin: each listed path lands where it says,
// anything else is missing, as the engine rejects a missing path.
const world = (on: On, lands: Readonly<Record<string, string>>, sources: readonly string[] = []) => {
  mock.env(on, { HOME })
  on('fs.stat', ($, e) => {
    const realPath = lands[e.path]
    return realPath === undefined ? { deny: `ENOENT: ${e.path}` } : { value: stat(realPath) }
  })
  on('fs.exists', ($, e) => ({ value: sources.includes(e.path) }))
  on('tool.call', () => ({ result: 'ran' }))
}

test('refuses an edit to a file linked into the store and names its source', async ($, on) => {
  world(on, { [`${HOME}/.claude/CLAUDE.md`]: STORE_FILE }, [SOURCE])
  const ran = await $.tool.call({
    tool: 'Edit',
    file_path: `${HOME}/.claude/CLAUDE.md`,
    old_string: 'a',
    new_string: 'b',
  })
  expect(ran.deny).toContain('is managed by Nix')
  expect(ran.deny).toContain(SOURCE)
})

test('refuses a new file under a directory linked into the store', async ($, on) => {
  world(on, { [`${HOME}/.claude/skills/caveman`]: STORE_SKILL })
  const ran = await $.tool.call({
    tool: 'Write',
    file_path: `${HOME}/.claude/skills/caveman/new.md`,
    content: 'x',
  })
  expect(ran.deny).toContain(`resolves to ${STORE_SKILL}`)
  expect(ran.deny).toContain('~/.nixfiles')
})

test('lets an edit outside the store through', async ($, on) => {
  world(on, { [`${HOME}/project/a.ts`]: `${HOME}/project/a.ts` })
  const ran = await $.tool.call({
    tool: 'Edit',
    file_path: `${HOME}/project/a.ts`,
    old_string: 'a',
    new_string: 'b',
  })
  expect(ran.deny).toBeUndefined()
  expect(ran.result).toBe('ran')
})

test('lets a path that resolves nowhere through', async ($, on) => {
  world(on, {})
  const ran = await $.tool.call({ tool: 'Write', file_path: '/tmp/nowhere/x.md', content: 'x' })
  expect(ran.deny).toBeUndefined()
})
