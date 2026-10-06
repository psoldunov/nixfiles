/**
 * Claude Code rules (`<claude dir>/rules/**\/*.md`).
 *
 * Claude Code loads a rule without `paths:` frontmatter into every session and
 * a rule with `paths:` only once a matching file is read or edited. The bridge
 * keeps that split: `always` rules render into one stable system-prompt
 * section, `scoped` rules are injected lazily by inject.ts.
 */

import * as path from "node:path";
import { type Diagnostic, type ParseFrontmatter, readMarkdown, toStringList } from "./frontmatter.ts";
import { isDirectory, listDir, realpathOr } from "./paths.ts";

export type ResourceSource = "user" | "project";

export interface Rule {
	/** Stable id used as the injection marker, e.g. `user:typescript/coding-style.md`. */
	id: string;
	source: ResourceSource;
	filePath: string;
	/** Empty for always-on rules. */
	paths: string[];
	body: string;
}

export interface RuleSet {
	always: Rule[];
	scoped: Rule[];
	diagnostics: Diagnostic[];
}

export interface RuleRoot {
	source: ResourceSource;
	dir: string;
}

export function discoverRules(roots: readonly RuleRoot[], parse: ParseFrontmatter): RuleSet {
	const always: Rule[] = [];
	const scoped: Rule[] = [];
	const diagnostics: Diagnostic[] = [];
	for (const root of roots) {
		for (const filePath of findMarkdown(root.dir)) {
			const result = readMarkdown(filePath, parse);
			if (!result.ok) {
				diagnostics.push(result.diagnostic);
				continue;
			}
			const body = result.doc.body.trim();
			if (body === "") continue;
			const rule: Rule = {
				id: `${root.source}:${path.relative(root.dir, filePath)}`,
				source: root.source,
				filePath,
				paths: toStringList(result.doc.frontmatter.paths),
				body,
			};
			(rule.paths.length > 0 ? scoped : always).push(rule);
		}
	}
	return { always, scoped, diagnostics };
}

/**
 * Markdown files below `dir`, sorted so the rendered section is stable across
 * sessions. Symlinked directories are followed once, so a link cycle ends.
 */
function findMarkdown(dir: string, visited: ReadonlySet<string> = new Set()): string[] {
	const real = realpathOr(dir);
	if (visited.has(real)) return [];
	const seen = new Set([...visited, real]);
	const files: string[] = [];
	for (const entry of listDir(dir)) {
		if (entry.name.startsWith(".")) continue;
		const full = path.join(dir, entry.name);
		if (entry.isDirectory() || (entry.isSymbolicLink() && isDirectory(full))) {
			files.push(...findMarkdown(full, seen));
		} else if (entry.name.endsWith(".md")) {
			files.push(full);
		}
	}
	return files.sort();
}

export const TOOL_GLOSSARY =
	"These instructions were written for Claude Code. Map its tool names to yours: Agent -> Agent, Read -> read, Write -> write, Edit/MultiEdit -> edit, Bash -> bash, Grep -> grep, Glob -> find, LS -> ls. Claude Code features with no counterpart here (hooks, plugins, plan mode, AskUserQuestion) do not apply.";

/** The `claude_rules` system-prompt section. Stable text, so the prompt cache survives. */
export function renderAlwaysSection(rules: readonly Rule[]): string {
	if (rules.length === 0) return "";
	const blocks = rules.map((rule) => `<rule path="${rule.filePath}">\n${rule.body}\n</rule>`);
	return [TOOL_GLOSSARY, "Follow these rules in every task:", ...blocks].join("\n\n");
}

export function ruleMarker(id: string): string {
	return `<claude-rule id="${id}"`;
}

/** The block appended to a tool result the first time a scoped rule applies. */
export function renderScopedRule(rule: Rule): string {
	return [
		`${ruleMarker(rule.id)} path="${rule.filePath}" applies-to="${rule.paths.join(", ")}">`,
		"This rule applies to files matching the patterns above. Follow it while working on them.",
		"",
		rule.body,
		"</claude-rule>",
	].join("\n");
}
