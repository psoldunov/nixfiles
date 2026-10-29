/**
 * Web search goes through BigTasty's SearXNG, as Claude Code's WebSearch hook
 * (../../claude-code/settings.nix) and Codex's `web_search = "disabled"`
 * arrange. pi-web-access's search tools are blocked and the model is pointed
 * at the searxng MCP server, which pi-mcp-adapter serves from
 * ~/.config/mcp/mcp.json. ../default.nix links this file into
 * ~/.pi/agent/extensions/.
 */

import type { ExtensionAPI } from '@earendil-works/pi-coding-agent'

// pi-web-access's search tools; its fetch_content stays available.
const BLOCKED = new Set(['web_search', 'source_check'])

export const REASON =
  'Built-in web search is disabled here. Search with mcp({ tool: "searxng_searxng_web_search", args: { query: "..." } }), ' +
  'and read a page with mcp({ tool: "searxng_web_url_read", args: { url: "..." } }).'

export default function searxngSearch(pi: ExtensionAPI) {
  pi.on('tool_call', event => (BLOCKED.has(event.toolName) ? { block: true, reason: REASON } : undefined))
}
