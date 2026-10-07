import { describe, expect, test } from 'claude-code/testing'
import {
  classify,
  contextHasHumanizer,
  gateMessage,
  isHumanFacingPath,
  isHumanizerSkill,
  longestString,
  MIN_EDIT_CHARS,
} from '../hooks/policy.ts'

const PARAGRAPH = 'This guide walks through installing the tool and wiring it into an existing project. '.repeat(4)

describe('paths', () => {
  test('docs, READMEs and locale files are human-facing', async () => {
    for (const path of [
      '/repo/README.md',
      '/repo/README',
      '/repo/CHANGELOG.md',
      '/repo/docs/guide.mdx',
      '/repo/site/content/post.markdown',
      '/repo/app/locales/en/common.json',
      '/repo/.github/pull_request_template.md',
    ]) {
      expect(isHumanFacingPath(path)).toBe(true)
    }
  })

  test('agent-facing and generated files are exempt', async () => {
    for (const path of [
      '/repo/CLAUDE.md',
      '/repo/CLAUDE.local.md',
      '/repo/AGENTS.md',
      '/home/u/.claude/rules/common/x.md',
      '/repo/modules/home/programs/claude-code/skills/humanizer/SKILL.md',
      '/repo/.context/plans/plan.md',
      '/repo/node_modules/pkg/README.md',
      '/nix/store/abc-docs/README.md',
    ]) {
      expect(isHumanFacingPath(path)).toBe(false)
    }
  })

  test('code files are not human-facing, whatever their name', async () => {
    for (const path of ['/repo/src/security.ts', '/repo/src/readme.ts', '/repo/src/page.tsx']) {
      expect(isHumanFacingPath(path)).toBe(false)
    }
  })
})

describe('writes', () => {
  test('a new human-facing file is gated at any length', async () => {
    expect(classify({ kind: 'write', path: '/repo/README.md', text: '# Hi', partial: false }).gated).toBe(true)
  })

  test('a small edit passes and a prose edit is gated', async () => {
    expect(classify({ kind: 'write', path: '/repo/README.md', text: 'v1.2.3', partial: true }).gated).toBe(false)
    expect(PARAGRAPH.length).toBeGreaterThan(MIN_EDIT_CHARS)
    expect(classify({ kind: 'write', path: '/repo/README.md', text: PARAGRAPH, partial: true }).gated).toBe(true)
  })
})

describe('shell', () => {
  const gated = (command: string): boolean => classify({ kind: 'shell', command }).gated

  test('GitHub posts are gated', async () => {
    expect(gated('gh pr create --title "Add x" --body "..."')).toBe(true)
    expect(gated('gh issue comment 12 --body-file notes.txt')).toBe(true)
    expect(gated('gh release create v1.0.0 --notes "..."')).toBe(true)
    expect(gated('gh pr edit 3 --body "new body"')).toBe(true)
    expect(gated('gh api repos/o/r/issues/1/comments -f body="hello"')).toBe(true)
  })

  test('GitHub reads and label edits pass', async () => {
    expect(gated('gh pr view 3 --json body')).toBe(false)
    expect(gated('gh pr edit 3 --add-label bug')).toBe(false)
    expect(gated('gh pr checks --watch')).toBe(false)
  })

  test('commit messages pass', async () => {
    expect(gated('git commit -m "feat: add x"')).toBe(false)
  })

  test('redirection into a doc is gated, into code or /dev/null it passes', async () => {
    expect(gated("cat > README.md <<'EOF'\n# Title\nEOF")).toBe(true)
    expect(gated('echo hi | tee -a docs/notes.md')).toBe(true)
    expect(gated('ls > /dev/null 2>&1')).toBe(false)
    expect(gated('echo x > src/index.ts')).toBe(false)
    expect(gated('cat CLAUDE.md > /tmp/CLAUDE.md')).toBe(false)
  })
})

describe('tools', () => {
  const gated = (name: string, input: unknown): boolean => classify({ kind: 'tool', name, input }).gated

  test('message sends are gated at any length', async () => {
    expect(gated('mcp__claude_ai_Slack__slack_send_message', { channel_id: 'C1', message: 'ok' })).toBe(true)
  })

  test('a bare tool name (pi MCP) is matched and named whole', async () => {
    const verdict = classify({ kind: 'tool', name: 'send_email', input: { to: 'a@b.c', body: 'hi' } })
    expect(verdict).toEqual({ gated: true, what: 'The `send_email` call' })
  })

  test('Linear and Sanity calls are gated only with prose in them', async () => {
    expect(gated('mcp__plugin_hm_linear-swiss-cheese__save_comment', { issueId: 'ABC-1', body: PARAGRAPH })).toBe(true)
    expect(gated('mcp__plugin_hm_linear-swiss-cheese__save_issue', { id: 'ABC-1', state: 'In Review' })).toBe(false)
    expect(gated('mcp__ensemblr__ensemblr_linear_create_comment', { issueId: 'ABC-1', body: PARAGRAPH })).toBe(true)
    expect(gated('mcp__claude_ai_Sanity__patch_documents', { patches: [{ set: { body: PARAGRAPH } }] })).toBe(true)
  })

  test('other tools pass', async () => {
    expect(gated('mcp__claude_ai_Vercel__list_projects', { teamId: PARAGRAPH })).toBe(false)
    expect(gated('mcp__ensemblr__ensemblr_send_follow_up', { message: PARAGRAPH })).toBe(false)
  })

  test('longestString looks into nested values', async () => {
    expect(longestString({ a: [{ b: 'xyz' }], c: 'x' })).toBe(3)
  })
})

describe('humanizer detection', () => {
  test('skill names', async () => {
    expect(isHumanizerSkill('humanizer')).toBe(true)
    expect(isHumanizerSkill('anthropic-skills:humanizer')).toBe(true)
    expect(isHumanizerSkill('/humanizer')).toBe(true)
    expect(isHumanizerSkill('humanizer-pro')).toBe(false)
  })

  test('pi context: a read of SKILL.md or a skill block counts', async () => {
    const read = { role: 'assistant', content: [{ type: 'toolCall', name: 'read', arguments: { path: '/home/u/.claude/skills/humanizer/SKILL.md' } }] }
    const block = { role: 'user', content: '<skill name="humanizer" location="/x/SKILL.md">body</skill>' }
    const other = { role: 'user', content: [{ type: 'text', text: 'write the README' }] }
    expect(contextHasHumanizer([other, read])).toBe(true)
    expect(contextHasHumanizer([block])).toBe(true)
    expect(contextHasHumanizer([other, null, 'x'])).toBe(false)
  })

  test('the gate message names the way to load the skill', async () => {
    expect(gateMessage('The file /r/README.md', 'claude')).toContain('Skill tool')
    expect(gateMessage('The file /r/README.md', 'pi')).toContain('SKILL.md')
  })
})
