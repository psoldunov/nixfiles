/**
 * Markdown-with-frontmatter reading shared by rules, skills and agents.
 *
 * pi's own `parseFrontmatter` (a real YAML parser) is injected rather than
 * imported, so these modules load under plain `node --test` without pi.
 */

import * as fs from "node:fs";

export interface ParsedMarkdown {
	frontmatter: Record<string, unknown>;
	body: string;
}

export type ParseFrontmatter = (content: string) => ParsedMarkdown;

export interface Diagnostic {
	path: string;
	message: string;
}

export type ReadResult = { ok: true; doc: ParsedMarkdown } | { ok: false; diagnostic: Diagnostic };

/** Read and parse one markdown file. A bad file becomes a diagnostic, never a throw. */
export function readMarkdown(filePath: string, parse: ParseFrontmatter): ReadResult {
	let content: string;
	try {
		content = fs.readFileSync(filePath, "utf-8");
	} catch (error) {
		return { ok: false, diagnostic: { path: filePath, message: errorMessage(error, "cannot read file") } };
	}
	try {
		return { ok: true, doc: parse(content) };
	} catch (error) {
		return { ok: false, diagnostic: { path: filePath, message: errorMessage(error, "invalid frontmatter") } };
	}
}

/**
 * Normalize a frontmatter list. Claude Code files use every spelling:
 *
 *     tools: Read, Grep          # comma-separated string
 *     tools: ["Read", "Grep"]    # flow sequence
 *     paths:                     # block sequence
 *       - "**\/*.ts"
 */
export function toStringList(value: unknown): string[] {
	const raw = Array.isArray(value) ? value : typeof value === "string" ? value.split(",") : [];
	return raw
		.filter((item): item is string => typeof item === "string")
		.map((item) => item.trim())
		.filter((item) => item.length > 0);
}

export function stringField(frontmatter: Record<string, unknown>, key: string): string | undefined {
	const value = frontmatter[key];
	return typeof value === "string" && value.trim() !== "" ? value.trim() : undefined;
}

export function errorMessage(error: unknown, fallback: string): string {
	return error instanceof Error ? error.message : fallback;
}
