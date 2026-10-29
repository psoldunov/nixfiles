// node --test modules/home/programs/clokkr-gate/clokkr-gate.test.mjs
import assert from 'node:assert/strict'
import { execFileSync } from 'node:child_process'
import { chmodSync, mkdirSync, symlinkSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { test } from 'node:test'
import { fileURLToPath } from 'node:url'
import { classify, decide, hasLogged, isRoot, localTime, MIN_TURN_MS, onPrompt, reposIn, repoOf } from './clokkr-gate.mjs'

const config = { clientOrgs: ['boundary-digital'], internalRepos: ['boundary-digital/almost-always'] }
const node = (id, kind, name, parent = null, notes = '') => ({ node: { id, kind, name, parent, notes, archived: false } })
const nodes = [
  node(7, 'folder', 'Amplify'),
  node(17, 'task', 'Agents', 7, 'Billed monthly\nrepo: boundary-digital/amplify-15'),
  node(9, 'folder', 'Helix'),
  node(21, 'task', 'Agents', 9, 'repo: Helix-ID/helix-next'),
]

test('repoOf reads ssh and https remotes', () => {
  assert.equal(repoOf('git@github.com:boundary-digital/amplify-15.git\n'), 'boundary-digital/amplify-15')
  assert.equal(repoOf('https://github.com/Helix-ID/helix-next'), 'helix-id/helix-next')
  assert.equal(repoOf('not a remote'), undefined)
})

test('reposIn takes every repo line and nothing else', () => {
  assert.deepEqual(reposIn('Billed monthly\nrepo: A/b\n  repo: c/D  \nrepository: x/y'), ['a/b', 'c/d'])
})

test('classify finds the task naming the repo, any org', () => {
  assert.deepEqual(classify('boundary-digital/amplify-15', nodes, config), { kind: 'known', task: { id: 17, path: 'Amplify/Agents' } })
  assert.deepEqual(classify('helix-id/helix-next', nodes, config), { kind: 'known', task: { id: 21, path: 'Helix/Agents' } })
})

test('classify sends unnamed client-org repos to setup, the rest nowhere', () => {
  assert.deepEqual(classify('boundary-digital/new-client', nodes, config), { kind: 'new' })
  assert.deepEqual(classify('boundary-digital/almost-always', nodes, config), { kind: 'none' })
  assert.deepEqual(classify('psoldunov/nixfiles', nodes, config), { kind: 'none' })
  assert.deepEqual(classify(undefined, nodes, config), { kind: 'none' })
})

test('hasLogged wants a session on the task starting near the turn', () => {
  const start = 1_000_000_000
  assert.equal(hasLogged([{ task: 17, begin: start + 30_000 }], 17, start), true)
  assert.equal(hasLogged([{ task: 17, begin: start + 600_000 }], 17, start), false)
  assert.equal(hasLogged([{ task: 21, begin: start }], 17, start), false)
})

test('decide asks once, then falls back', () => {
  const known = { kind: 'known', task: { id: 17, path: 'Amplify/Agents' } }
  const state = { start: 0, prompt: 'fix the header' }
  const now = MIN_TURN_MS + 1
  const asked = decide({ state, now, repo: 'boundary-digital/amplify-15', cls: known, logged: false })
  assert.equal(asked.act, 'ask')
  assert.match(asked.message, /add_session with task "17" \(Amplify\/Agents\)/)
  assert.equal(decide({ state: { ...state, end: now, asked: true }, now, cls: known, logged: true }).act, 'allow')
  assert.equal(decide({ state: { ...state, end: now, asked: true }, now, cls: known, logged: false }).act, 'fallback')
})

test('decide skips short turns and repos that are not client work', () => {
  const known = { kind: 'known', task: { id: 17, path: 'Amplify/Agents' } }
  assert.equal(decide({ state: { start: 0 }, now: MIN_TURN_MS - 1, cls: known, logged: false }).act, 'allow')
  assert.equal(decide({ state: { start: 0 }, now: MIN_TURN_MS * 5, cls: { kind: 'none' }, logged: false }).act, 'allow')
  assert.equal(decide({ state: undefined, now: 0, cls: known, logged: false }).act, 'allow')
})

test('decide has a new client set up before logging', () => {
  const { act, message } = decide({ state: { start: 0 }, now: MIN_TURN_MS * 2, repo: 'boundary-digital/new-client', cls: { kind: 'new' }, logged: false })
  assert.equal(act, 'ask')
  assert.match(message, /create_folder/)
  assert.match(message, /repo: boundary-digital\/new-client/)
})

test('onPrompt starts a turn, but keeps a blocked one pi is continuing', () => {
  assert.deepEqual(onPrompt(undefined, 5, 'NOTICE\n\n  fix the header  '), { start: 5, prompt: 'fix the header' })
  const blocked = { start: 1, prompt: 'p', end: 100, asked: true }
  assert.equal(onPrompt(blocked, 150, 'log it'), blocked)
  assert.equal(onPrompt(blocked, 100 + 10 * 60_000, 'next task').start, 100 + 10 * 60_000)
})

test('isRoot skips sub-agents of every runtime', () => {
  assert.equal(isRoot({}, {}), true)
  assert.equal(isRoot({}, { ENSEMBLR_CONTROL_DEPTH: '0' }), true)
  assert.equal(isRoot({}, { ENSEMBLR_CONTROL_DEPTH: '1' }), false)
  assert.equal(isRoot({}, { PI_CLAUDE_BRIDGE_DEPTH: '2' }), false)
  assert.equal(isRoot({ agent_id: 'a1' }, {}), false)
})

test('localTime is RFC 3339 that parses back to the same instant', () => {
  const ms = Date.UTC(2026, 9, 29, 8, 2, 31)
  assert.match(localTime(ms), /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d[+-]\d\d:\d\d$/)
  assert.equal(Date.parse(localTime(ms)), ms)
})

// The hook command end to end, against a fake clokkr that logs its arguments.
// A client repo, and a fake clokkr that logs its arguments and has no sessions.
function fixture() {
  const root = mkdtempSync(join(tmpdir(), 'clokkr-gate-'))
  const repo = join(root, 'repo')
  mkdirSync(repo)
  execFileSync('git', ['init', '-q', repo])
  execFileSync('git', ['-C', repo, 'remote', 'add', 'origin', 'git@github.com:boundary-digital/amplify-15.git'])
  const calls = join(root, 'calls')
  const cli = join(root, 'clokkr')
  writeFileSync(join(root, 'tasks.json'), JSON.stringify({ nodes }))
  writeFileSync(
    cli,
    `#!/bin/sh\necho "$*" >> ${calls}\ncase "$1" in tasks) cat ${join(root, 'tasks.json')};; sessions) echo '[]';; esac\n`,
  )
  chmodSync(cli, 0o755)
  mkdirSync(join(root, 'config', 'clokkr-gate'), { recursive: true })
  writeFileSync(join(root, 'config', 'clokkr-gate', 'config.json'), JSON.stringify({ ...config, cli }))
  const env = { PATH: process.env.PATH, XDG_CONFIG_HOME: join(root, 'config'), XDG_STATE_HOME: join(root, 'state') }
  const sessionAdd = () => readFileSync(calls, 'utf8').split('\n').find(line => line.startsWith('session add'))
  return { root, repo, env, sessionAdd }
}

const realScript = fileURLToPath(new URL('./clokkr-gate.mjs', import.meta.url))

for (const viaLink of [false, true])
test(`hook: blocks the first stop, writes the session at the second${viaLink ? ' (run through a symlink, as home-manager installs it)' : ''}`, () => {
  const { root, repo, env, sessionAdd } = fixture()
  const script = viaLink ? join(root, 'clokkr-gate.mjs') : realScript
  if (viaLink) symlinkSync(realScript, script)
  const hook = (event, input) => execFileSync('node', [script, event], { env, input: JSON.stringify(input), encoding: 'utf8' })
  const statePath = join(root, 'state', 'clokkr-gate', 's1.json')

  hook('prompt', { session_id: 's1', prompt: 'fix the header' })
  // Age the turn past the minimum.
  const state = JSON.parse(readFileSync(statePath, 'utf8'))
  writeFileSync(statePath, JSON.stringify({ ...state, start: state.start - 5 * 60_000 }))

  const first = JSON.parse(hook('stop', { session_id: 's1', cwd: repo }))
  assert.equal(first.decision, 'block')
  assert.match(first.reason, /add_session with task "17"/)

  assert.equal(hook('stop', { session_id: 's1', cwd: repo, last_assistant_message: 'Header fixed.\nMore.' }), '')
  assert.match(sessionAdd(), /^session add 17 --from \S+ --to \S+ --notes Header fixed\. \(logged by clokkr-gate\)$/)
})

test('pi: asks with a follow-up, keeps the turn through it, then falls back', async t => {
  const { repo, env, sessionAdd } = fixture()
  Object.assign(process.env, env)
  delete process.env.ENSEMBLR_CONTROL_DEPTH
  delete process.env.PI_CLAUDE_BRIDGE_DEPTH
  let now = 1_000_000
  t.mock.method(Date, 'now', () => now)
  const handlers = {}
  const sent = []
  const pi = { on: (event, handler) => (handlers[event] = handler), sendUserMessage: async text => sent.push(text) }
  const { default: clokkrGate } = await import('./index.ts')
  clokkrGate(pi)
  const ctx = { cwd: repo, hasUI: false }
  const answer = { messages: [{ role: 'assistant', content: [{ type: 'text', text: 'Header fixed.' }] }] }

  handlers.before_agent_start({ messageType: 'user', prompt: 'fix the header' })
  now += 5 * 60_000
  await handlers.agent_end(answer, ctx)
  assert.equal(sent.length, 1)
  assert.match(sent[0], /add_session with task "17"/)

  // The follow-up run is the same turn; it ends without logging.
  now += 10_000
  handlers.before_agent_start({ messageType: 'user', prompt: sent[0] })
  await handlers.agent_end(answer, ctx)
  assert.equal(sent.length, 1)
  assert.match(sessionAdd(), /^session add 17 .* --notes Header fixed\. \(logged by clokkr-gate\)$/)
})
