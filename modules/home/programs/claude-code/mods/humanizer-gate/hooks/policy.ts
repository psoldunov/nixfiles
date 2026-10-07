/**
 * What counts as human-facing text, shared by the Claude Code hooks
 * (./register.ts) and the pi extension (../index.ts).
 *
 * Pure functions with no imports, in erasable TypeScript only, so the Claude
 * Code engine, pi's jiti and plain Node all load this file as it is.
 */

export type Target =
  /** A file write. `partial` marks an edit, whose `text` is the new text only. */
  | { kind: 'write'; path: string; text: string; partial: boolean }
  | { kind: 'shell'; command: string }
  /** Any other tool, MCP ones included, with its arguments. */
  | { kind: 'tool'; name: string; input: unknown }

export type Verdict = { gated: false } | { gated: true; what: string }

export type Agent = 'claude' | 'pi'

/** Edits adding less text than this pass: typo fixes, version bumps. */
export const MIN_EDIT_CHARS = 200
/** Tool calls whose longest string is shorter than this pass: state or title-only updates. */
export const MIN_TOOL_CHARS = 80

const PASS: Verdict = { gated: false }

// Files people read. A prose extension anywhere counts, unless the file is agent-facing.
const PROSE_FILE = /\.(md|mdx|markdown|rst|adoc)$/i
const PROSE_NAME = /^(readme|changelog|changes|contributing|release[-_]?notes)(\.txt)?$/i
const COPY_DIR = /(^|\/)(locales?|i18n|translations)\//i

// Files agents read: instructions, skills, prompts, plans, memory.
const AGENT_NAME = /^(claude(\.local)?|agents|gemini|skill|copilot-instructions)\.md$/i
const AGENT_DIR =
  /(^|\/)(\.claude|\.pi|\.agents|\.codex|\.cursor|\.context|rules|skills|agents|prompts|commands|plans|node_modules)\//
const NIX_STORE = /^\/nix\/store\//

// Shell commands that publish prose.
const GH_POST = /\bgh\s+(pr|issue)\s+(create|comment)\b|\bgh\s+release\s+create\b/
const GH_EDIT = /\bgh\s+(pr|issue|release)\s+(edit|review)\b/
const GH_EDIT_TEXT = /\s(--body|--body-file|--notes|--notes-file|-b|-F|-n)(\s|=|$)/
const GH_API_TEXT = /\bgh\s+api\b.*\/(comments|reviews|issues|pulls)\b.*\s-[fF]\s+body=/
const REDIRECT = /(?:^|[^<>&0-9])(?:>>?|\btee\s+(?:-a\s+)?)\s*["']?([^\s"'|;&<>()]+)/g

// MCP tools (`mcp__<server>__<name>`) that send a message, at any length.
const SEND_TOOL =
  /(^|__)(slack_send_message|slack_send_message_draft|slack_schedule_message|slack_create_canvas|slack_update_canvas|send_email|send_message|create_draft|draft_email|reply_email)$/
// MCP tools that store prose, gated when a string argument reaches MIN_TOOL_CHARS.
const PROSE_TOOL =
  /(^|__)(save_issue|save_comment|save_document|save_status_update|save_release_note|save_project|save_diff_comment|ensemblr_linear_create_comment|ensemblr_linear_create_issue|ensemblr_linear_update_issue|create_documents|patch_documents|create_version)$/

const HUMANIZER_NAME = /^\/?([\w-]+:)?humanizer$/
const HUMANIZER_FILE = /(^|\/)humanizer\/SKILL\.md$/
const HUMANIZER_BLOCK = /<skill name="([\w-]+:)?humanizer"/

const baseName = (path: string): string => path.slice(path.lastIndexOf('/') + 1)

/** True for a file people other than agents read. */
export function isHumanFacingPath(rawPath: string): boolean {
  const path = rawPath.replace(/\\/g, '/')
  const base = baseName(path)
  if (NIX_STORE.test(path) || AGENT_NAME.test(base) || AGENT_DIR.test(path)) return false
  return PROSE_FILE.test(base) || PROSE_NAME.test(base) || COPY_DIR.test(path)
}

function classifyWrite(path: string, text: string, partial: boolean): Verdict {
  if (!isHumanFacingPath(path)) return PASS
  if (partial && text.trim().length < MIN_EDIT_CHARS) return PASS
  return { gated: true, what: `The file ${path}` }
}

function redirectTargets(command: string): string[] {
  return [...command.matchAll(REDIRECT)].map(match => match[1] ?? '').filter(path => path !== '')
}

function classifyShell(command: string): Verdict {
  const post = command.match(GH_POST)
  if (post) return { gated: true, what: `\`${post[0]}\`` }
  const edit = command.match(GH_EDIT)
  if (edit && GH_EDIT_TEXT.test(command)) return { gated: true, what: `\`${edit[0]}\`` }
  if (GH_API_TEXT.test(command)) return { gated: true, what: 'A GitHub comment posted through `gh api`' }
  const file = redirectTargets(command).find(isHumanFacingPath)
  if (file !== undefined) return { gated: true, what: `Shell output written to ${file}` }
  return PASS
}

/** Length of the longest string anywhere in `value`, a few levels deep. */
export function longestString(value: unknown, depth = 0): number {
  if (typeof value === 'string') return value.length
  if (depth > 6 || value === null || typeof value !== 'object') return 0
  const children: unknown[] = Array.isArray(value) ? value : Object.values(value)
  return children.reduce<number>((max, child) => Math.max(max, longestString(child, depth + 1)), 0)
}

/** `slack_send_message` out of `mcp__claude_ai_Slack__slack_send_message`; a bare name as it is. */
const shortToolName = (name: string): string => {
  const cut = name.lastIndexOf('__')
  return cut === -1 ? name : name.slice(cut + 2)
}

function classifyTool(name: string, input: unknown): Verdict {
  const short = shortToolName(name)
  if (SEND_TOOL.test(name)) return { gated: true, what: `The \`${short}\` call` }
  if (PROSE_TOOL.test(name) && longestString(input) >= MIN_TOOL_CHARS) {
    return { gated: true, what: `The text in the \`${short}\` call` }
  }
  return PASS
}

/** Whether `target` writes or sends text for people other than the user. */
export function classify(target: Target): Verdict {
  switch (target.kind) {
    case 'write':
      return classifyWrite(target.path, target.text, target.partial)
    case 'shell':
      return classifyShell(target.command)
    case 'tool':
      return classifyTool(target.name, target.input)
  }
}

/** The local `humanizer` skill or a plugin's copy (`anthropic-skills:humanizer`). */
export function isHumanizerSkill(name: string): boolean {
  return HUMANIZER_NAME.test(name.trim())
}

type Part = { type?: unknown; text?: unknown; name?: unknown; arguments?: unknown }

function partLoadsHumanizer(part: Part): boolean {
  if (part.type === 'text' && typeof part.text === 'string') return HUMANIZER_BLOCK.test(part.text)
  if (part.type !== 'toolCall' || part.name !== 'read') return false
  const path = (part.arguments as { path?: unknown } | undefined)?.path
  return typeof path === 'string' && HUMANIZER_FILE.test(path)
}

/**
 * Whether pi's context holds the skill: a `read` of its SKILL.md, or the
 * `<skill name="humanizer">` block `/skill:humanizer` and `/humanizer` send.
 */
export function contextHasHumanizer(messages: readonly unknown[]): boolean {
  return messages.some(message => {
    if (message === null || typeof message !== 'object') return false
    const content = (message as { content?: unknown }).content
    if (typeof content === 'string') return HUMANIZER_BLOCK.test(content)
    return Array.isArray(content) && content.some(part => part !== null && typeof part === 'object' && partLoadsHumanizer(part as Part))
  })
}

const HOW_TO_LOAD: Record<Agent, string> = {
  claude: 'Load the humanizer skill first (Skill tool, skill "humanizer")',
  pi: 'Load the humanizer skill first (read its SKILL.md, path in the skill listing)',
}

/** The refusal the agent reads, naming what was gated and how to get past it. */
export function gateMessage(what: string, agent: Agent): string {
  return [
    `humanizer-gate: ${what} is text for people other than the user.`,
    `${HOW_TO_LOAD[agent]}, run its pass on this text, then retry the call with the humanized text.`,
    'Agent-facing files (CLAUDE.md, rules, skills, plans) and replies to the user are exempt; see the human-facing-text rule.',
  ].join(' ')
}
