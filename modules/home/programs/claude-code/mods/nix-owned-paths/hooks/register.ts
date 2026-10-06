import type { EngineInterface, Register } from 'claude-code'

const NIX_STORE = '/nix/store/'
const NIXFILES = '.nixfiles'
const CLAUDE_MODULE = 'modules/home/programs/claude-code'

const parentOf = (path: string): string | undefined => {
  const trimmed = path.replace(/\/+$/, '')
  const cut = trimmed.lastIndexOf('/')
  if (cut > 0) return trimmed.slice(0, cut)
  return cut === 0 && trimmed !== '' ? '/' : undefined
}

// Where the path lands, every link followed. A file that does not exist yet
// lands wherever its nearest existing parent does, so a new file under a
// linked directory is caught too. Undefined when nothing on the way resolves.
const landing = async ($: EngineInterface, path: string): Promise<string | undefined> => {
  for (let at: string | undefined = path; at !== undefined; at = parentOf(at)) {
    const stat = await $.fs.stat(at, { resolve: true }).catch(() => undefined)
    if (stat !== undefined) return stat.realPath
  }
  return undefined
}

// Files under ~/.claude mirror the claude-code module one to one; anything
// else gets the generic pointer.
const sourceHint = async ($: EngineInterface, path: string): Promise<string> => {
  const home = await $.env.get('HOME')
  const claudeDir = `${home}/.claude/`
  if (home !== undefined && path.startsWith(claudeDir)) {
    const source = `${home}/${NIXFILES}/${CLAUDE_MODULE}/${path.slice(claudeDir.length)}`
    if (await $.fs.exists(source)) return `Edit ${source} instead, then run rebuild_system.`
  }
  return `Edit its source in ~/${NIXFILES} (or bump the flake input it comes from), then run rebuild_system.`
}

const refusal = async ($: EngineInterface, path: string): Promise<string | undefined> => {
  const real = await landing($, path)
  if (real === undefined || !real.startsWith(NIX_STORE)) return undefined
  return `${path} is managed by Nix (it resolves to ${real}). ${await sourceHint($, path)}`
}

export const register: Register = on => {
  on('tool.call', { tool: 'Edit' }, async ($, e, next) => {
    const deny = await refusal($, e.file_path)
    return deny === undefined ? next(e) : { deny }
  })

  on('tool.call', { tool: 'Write' }, async ($, e, next) => {
    const deny = await refusal($, e.file_path)
    return deny === undefined ? next(e) : { deny }
  })

  on('tool.call', { tool: 'NotebookEdit' }, async ($, e, next) => {
    const deny = await refusal($, e.notebook_path)
    return deny === undefined ? next(e) : { deny }
  })
}
