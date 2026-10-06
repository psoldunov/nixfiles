/**
 * Lazy injection, the pi side of Claude Code's "load when a matching file is
 * touched": path-scoped rules and nested CLAUDE.md files are appended to the
 * first read/edit/write result they apply to.
 *
 * Each block carries a marker (`<claude-rule id=...`, `<claude-memory id=...`).
 * A block is skipped while its marker is still in the model's context. Once
 * compaction summarizes it away the marker is gone, and the next matching file
 * injects it again, which is what Claude Code does too.
 */

import * as path from "node:path";
import { type MemoryFile, nestedMemoryPaths, readText, renderNestedMemory } from "./memory.ts";
import { matchesAnyGlob } from "./paths.ts";
import { type Rule, renderScopedRule } from "./rules.ts";

const MARKER = /<claude-(rule|memory) id="([^"]+)"/g;

/** Marker keys (`rule:<id>`, `memory:<path>`) present anywhere in `messages`. */
export function collectMarkers(messages: readonly unknown[]): Set<string> {
	const found = new Set<string>();
	for (const message of messages) {
		for (const text of messageTexts(message)) {
			for (const match of text.matchAll(MARKER)) found.add(`${match[1]}:${match[2]}`);
		}
	}
	return found;
}

function messageTexts(message: unknown): string[] {
	if (message === null || typeof message !== "object") return [];
	const content = (message as { content?: unknown }).content;
	if (typeof content === "string") return [content];
	if (!Array.isArray(content)) return [];
	return content
		.filter((part): part is { type: "text"; text: string } => part?.type === "text" && typeof part.text === "string")
		.map((part) => part.text);
}

export interface InjectionInput {
	filePath: string;
	/** Nested CLAUDE.md files are looked up below this directory. */
	cwd: string;
	/** `paths:` globs are relative to the project root, as in Claude Code. */
	projectRoot: string;
	scopedRules: readonly Rule[];
	nestedMemory: boolean;
	/** Keys already in context or already injected earlier in this turn. */
	skip: ReadonlySet<string>;
}

export interface Injection {
	keys: string[];
	text: string;
}

export function planInjection(input: InjectionInput): Injection | undefined {
	const keys: string[] = [];
	const blocks: string[] = [];
	if (input.nestedMemory) {
		for (const memoryPath of nestedMemoryPaths(input.filePath, input.cwd)) {
			const key = `memory:${memoryPath}`;
			if (input.skip.has(key)) continue;
			const content = readText(memoryPath)?.trim();
			if (!content) continue;
			const file: MemoryFile = { path: memoryPath, content };
			keys.push(key);
			blocks.push(renderNestedMemory(file));
		}
	}
	for (const rule of input.scopedRules) {
		const key = `rule:${rule.id}`;
		const absolute = path.resolve(input.cwd, input.filePath);
		if (input.skip.has(key) || !matchesAnyGlob(absolute, rule.paths, input.projectRoot)) continue;
		keys.push(key);
		blocks.push(renderScopedRule(rule));
	}
	if (blocks.length === 0) return undefined;
	return { keys, text: `<system-reminder>\n${blocks.join("\n\n")}\n</system-reminder>` };
}
