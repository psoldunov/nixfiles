/**
 * clokkr-gate: root agents log the time they spend on client repos to Clokkr.
 *
 * One file serves three agents. Claude Code and Codex run it as a hook command,
 * `node clokkr-gate.mjs prompt|stop`, with the hook's JSON on stdin; pi's
 * index.ts imports the functions below.
 *
 * The hooks measure and the agent writes. A turn's start is noted at the
 * prompt and its end at the first stop, which is blocked once with the exact
 * values for the Clokkr MCP `add_session`. If the agent still has not logged
 * at the next stop, the hook writes the session itself with the clokkr CLI.
 *
 * The repo -> client map lives in Clokkr: an `Agents` task whose notes hold a
 * `repo: owner/name` line. A repo in a client org that no task names yet has
 * the agent find or create the client's folder and task before it logs.
 */
import { execFileSync } from 'node:child_process'
import { mkdirSync, readFileSync, realpathSync, rmSync, writeFileSync } from 'node:fs'
import { homedir } from 'node:os'
import { join } from 'node:path'
import { pathToFileURL } from 'node:url'

// Shorter turns are not logged.
export const MIN_TURN_MS = 60_000
// How far a logged session's start may sit from the turn's start and still count.
const START_SLACK_MS = 90_000
// A prompt this soon after a block is pi's continuation of the blocked turn.
const CONTINUE_MS = 120_000
const UNSORTED = 'Unsorted'
const TASK = 'Agents'

const xdg = (variable, fallback) => process.env[variable] || join(homedir(), fallback)
const configPath = () => join(xdg('XDG_CONFIG_HOME', '.config'), 'clokkr-gate', 'config.json')
const statePath = key => join(xdg('XDG_STATE_HOME', '.local/state'), 'clokkr-gate', `${key.replace(/[^\w-]/g, '_')}.json`)

/** `{ cli, clientOrgs, internalRepos }` as nix wrote it, or undefined on a host without Clokkr. */
export function loadConfig() {
  try {
    return JSON.parse(readFileSync(configPath(), 'utf8'))
  } catch {
    return undefined
  }
}

const nested = depth => depth !== undefined && depth !== '' && depth !== '0'

/** Whether this is a root conversation: sub-agents are covered by their root's turn. */
export const isRoot = (input, env = process.env) =>
  !input.agent_id && !nested(env.ENSEMBLR_CONTROL_DEPTH) && !nested(env.PI_CLAUDE_BRIDGE_DEPTH)

/** `owner/name` from a git remote URL (ssh or https), lowercased, or undefined. */
export function repoOf(url) {
  const match = /[:/]([^/:\s]+)\/([^/\s]+?)(?:\.git)?\/?$/.exec(url.trim())
  return match ? `${match[1]}/${match[2]}`.toLowerCase() : undefined
}

/** The repos a task's notes name, one `repo: owner/name` line each, lowercased. */
export const reposIn = notes => [...notes.matchAll(/^\s*repo:\s*(\S+)\s*$/gim)].map(match => match[1].toLowerCase())

const pathOf = (node, byId) => {
  const parent = byId.get(node.parent)
  return parent ? `${pathOf(parent, byId)}/${node.name}` : node.name
}

/**
 * Where a repo's agent time goes, from `clokkr tasks --json` nodes: the task
 * whose notes name it, a new client to set up (its org is a client org), or nowhere.
 */
export function classify(repo, nodes, config) {
  if (!repo) return { kind: 'none' }
  const plain = nodes.map(entry => entry.node)
  const byId = new Map(plain.map(node => [node.id, node]))
  const task = plain.find(node => node.kind === 'task' && !node.archived && reposIn(node.notes ?? '').includes(repo))
  if (task) return { kind: 'known', task: { id: task.id, path: pathOf(task, byId) } }
  const lower = list => (list ?? []).map(item => item.toLowerCase())
  const isClient = lower(config.clientOrgs).includes(repo.split('/')[0]) && !lower(config.internalRepos).includes(repo)
  return isClient ? { kind: 'new' } : { kind: 'none' }
}

/** Whether a session on the task (from `clokkr sessions --json`) starts where the turn did. */
export const hasLogged = (sessions, taskId, start) =>
  sessions.some(session => session.task === taskId && Math.abs(session.begin - start) <= START_SLACK_MS)

/** RFC 3339 in local time, which Clokkr reads: `2026-10-29T10:02:31+02:00`. */
export function localTime(ms) {
  const date = new Date(ms)
  const pad = n => String(Math.trunc(Math.abs(n))).padStart(2, '0')
  const offset = -date.getTimezoneOffset()
  const day = `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
  const time = `${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`
  return `${day}T${time}${offset < 0 ? '-' : '+'}${pad(offset / 60)}:${pad(offset % 60)}`
}

const NOTES = 'notes: one line on what you did this turn, for someone reading an invoice'

const logMessage = (task, start, end) =>
  `This turn was client work: log it to Clokkr before you finish. Call the Clokkr MCP tool add_session with ` +
  `task "${task.id}" (${task.path}), start "${localTime(start)}", end "${localTime(end)}", and ${NOTES}. ` +
  `Then finish; your answer does not need to mention it.`

const newClientMessage = (repo, start, end) =>
  [
    `This turn was work on ${repo}, a client repo that no Clokkr task names yet. Before you finish:`,
    `1. Call the Clokkr MCP tool list_tasks and find this client's folder. Match the client's name (its project in the Almost Always Linear workspace, the README, the repo name), not the repo name verbatim.`,
    `2. If that folder has an "${TASK}" task, add the line "repo: ${repo}" to its notes with update_node, keeping the lines already there. If it has none, create_task "${TASK}" in it with billable false and notes "repo: ${repo}". If no folder fits, create_folder with the client's name first.`,
    `3. Call add_session on that ${TASK} task with start "${localTime(start)}", end "${localTime(end)}", and ${NOTES}.`,
    `4. Tell the user in your answer which Clokkr folder and task you used or created.`,
  ].join('\n')

/** The turn as noted at a prompt: `{ start, prompt }`, or the blocked turn pi is continuing. */
export function onPrompt(state, now, prompt) {
  if (state?.asked && now - state.end < CONTINUE_MS) return state
  return { start: now, prompt: lastLine(prompt) }
}

/**
 * What to do at a stop, given the noted turn, the repo's classification and
 * whether the known task already holds the session: allow it, ask the agent
 * to log (blocking the stop once), or write the session as a fallback.
 */
export function decide({ state, now, repo, cls, logged }) {
  if (!state || cls.kind === 'none') return { act: 'allow' }
  if (cls.kind === 'known' && logged) return { act: 'allow' }
  if (state.asked) return { act: 'fallback' }
  if (now - state.start < MIN_TURN_MS) return { act: 'allow' }
  const message = cls.kind === 'known' ? logMessage(cls.task, state.start, now) : newClientMessage(repo, state.start, now)
  return { act: 'ask', message }
}

const lines = text =>
  (text ?? '')
    .split('\n')
    .map(line => line.trim().slice(0, 160))
    .filter(Boolean)
// A prompt's last line: Ensemblr puts its own notices above the person's words.
const lastLine = text => lines(text).at(-1) ?? ''

const run = (cli, args) => execFileSync(cli, args, { encoding: 'utf8', timeout: 10_000, stdio: ['ignore', 'pipe', 'pipe'] })

function remoteRepo(cwd) {
  try {
    return repoOf(execFileSync('git', ['-C', cwd, 'remote', 'get-url', 'origin'], { encoding: 'utf8', timeout: 5_000, stdio: ['ignore', 'pipe', 'ignore'] }))
  } catch {
    return undefined
  }
}

const day = ms => localTime(ms).slice(0, 10)

function sessionsOf(cli, taskId, start, now) {
  return JSON.parse(run(cli, ['sessions', '--json', '--task', String(taskId), '--from', day(start), '--to', day(now)]))
}

// The holding task for a new client's turn the agent did not log: Unsorted/Agents.
function unsortedTask(cli, nodes) {
  const plain = nodes.map(entry => entry.node)
  const folder = plain.find(node => node.kind === 'folder' && node.parent === null && node.name === UNSORTED)
  const hasTask = folder && plain.some(node => node.kind === 'task' && node.parent === folder.id && node.name === TASK)
  if (!folder) run(cli, ['folder', 'add', UNSORTED])
  if (!hasTask) run(cli, ['task', 'add', TASK, '--folder', UNSORTED, '--not-billable'])
  return `${UNSORTED}/${TASK}`
}

function writeFallback(cli, { cls, nodes, state, repo, lastMessage }) {
  const what = lines(lastMessage)[0] || state.prompt || 'Agent turn'
  const known = cls.kind === 'known'
  const task = known ? String(cls.task.id) : unsortedTask(cli, nodes)
  const notes = `${known ? '' : `repo: ${repo}; `}${what} (logged by clokkr-gate)`
  run(cli, ['session', 'add', task, '--from', localTime(state.start), '--to', localTime(state.end), '--notes', notes])
}

/**
 * The stop, end to end: classify the repo, check Clokkr, decide. Answers
 * `{ state, block }`: the state to keep (none clears it) and the message that
 * blocks the stop, if any.
 */
export function stop(config, state, now, cwd, lastMessage) {
  if (!state || (!state.asked && now - state.start < MIN_TURN_MS)) return {}
  const repo = remoteRepo(cwd)
  if (!repo) return {}
  const { nodes } = JSON.parse(run(config.cli, ['tasks', '--json']))
  const cls = classify(repo, nodes, config)
  const logged = cls.kind === 'known' && hasLogged(sessionsOf(config.cli, cls.task.id, state.start, now), cls.task.id, state.start)
  const decision = decide({ state, now, repo, cls, logged })
  if (decision.act === 'ask') return { state: { ...state, end: now, asked: true }, block: decision.message }
  if (decision.act === 'fallback') writeFallback(config.cli, { cls, nodes, state, repo, lastMessage })
  return {}
}

function load(key) {
  try {
    return JSON.parse(readFileSync(statePath(key), 'utf8'))
  } catch {
    return undefined
  }
}

function save(key, state) {
  const path = statePath(key)
  if (!state) return rmSync(path, { force: true })
  mkdirSync(join(path, '..'), { recursive: true })
  writeFileSync(path, JSON.stringify(state))
}

function main(event) {
  const input = JSON.parse(readFileSync(0, 'utf8') || '{}')
  const config = loadConfig()
  if (!config || !input.session_id || !isRoot(input)) return
  const now = Date.now()
  if (event === 'prompt') return save(input.session_id, onPrompt(load(input.session_id), now, input.prompt))
  if (event !== 'stop') return
  const out = stop(config, load(input.session_id), now, input.cwd ?? process.cwd(), input.last_assistant_message)
  save(input.session_id, out.state)
  if (out.block) process.stdout.write(JSON.stringify({ decision: 'block', reason: out.block }))
}

// The hook runs through a home-manager symlink and Node resolves the main module
// to its realpath, so argv[1] must be resolved too.
if (process.argv[1] && import.meta.url === pathToFileURL(realpathSync(process.argv[1])).href) {
  try {
    main(process.argv[2])
  } catch (error) {
    // Time tracking must never wedge a turn: report and let the stop through.
    process.stderr.write(`clokkr-gate: ${error?.message ?? error}\n`)
  }
}
