/** Test fixtures: temp directory trees and a small stand-in for pi's YAML frontmatter parser. */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { ParsedMarkdown } from "../frontmatter.ts";

/** Write `files` (relative path -> content) under a fresh temp directory and return its path. */
export function makeTree(files: Record<string, string>): string {
	const root = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), "claude-bridge-test-")));
	for (const [rel, content] of Object.entries(files)) {
		const full = path.join(root, rel);
		fs.mkdirSync(path.dirname(full), { recursive: true });
		fs.writeFileSync(full, content);
	}
	return root;
}

export function removeTree(root: string): void {
	fs.rmSync(root, { recursive: true, force: true });
}

export function md(frontmatter: string, body: string): string {
	return `---\n${frontmatter.trim()}\n---\n${body}`;
}

/**
 * Enough YAML for the fixtures: `key: value`, `key: [a, "b"]`, `key: >` folded
 * text, and `key:` followed by `- item` lines.
 */
export function parseFixture(content: string): ParsedMarkdown {
	const match = content.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)$/);
	if (!match) return { frontmatter: {}, body: content };
	const frontmatter: Record<string, unknown> = {};
	let listKey: string | undefined;
	for (const line of match[1].split("\n")) {
		const item = line.match(/^\s+-\s+(.*)$/);
		if (item && listKey) {
			(frontmatter[listKey] as string[]).push(unquote(item[1]));
			continue;
		}
		const pair = line.match(/^([\w-]+):\s*(.*)$/);
		if (!pair) continue;
		const [, key, raw] = pair;
		listKey = undefined;
		if (raw === "") {
			frontmatter[key] = [];
			listKey = key;
		} else if (raw.startsWith("[")) {
			frontmatter[key] = raw.slice(1, -1).split(",").map(unquote).filter(Boolean);
		} else if (raw === "true" || raw === "false") {
			frontmatter[key] = raw === "true";
		} else {
			frontmatter[key] = unquote(raw);
		}
	}
	return { frontmatter, body: match[2] };
}

function unquote(value: string): string {
	return value.trim().replace(/^["']|["']$/g, "");
}
