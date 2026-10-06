/**
 * Claude Code skills, discovered the way Claude Code finds them rather than by
 * pi's recursive scan:
 *   - project: `<project>/.claude/skills/<name>/SKILL.md` (trusted projects only)
 *   - user:    `<claude dir>/skills/<name>/SKILL.md`
 *   - plugin:  each plugin's manifest skill paths (see plugins.ts)
 *   - synced:  `<claude dir>/skills/synced/<bucket>/<name>/SKILL.md` (claude.ai)
 *
 * pi still loads them itself (from the paths handed over in
 * `resources_discover`) and still lists only name, description and location.
 * `applyListingBudget` then trims that listing to Claude Code's budget.
 */

import * as path from "node:path";
import { type Diagnostic, type ParseFrontmatter, readMarkdown, stringField } from "./frontmatter.ts";
import { isDirectory, isFile, listDir, matchesAny } from "./paths.ts";
import type { Plugin } from "./plugins.ts";

export interface SkillEntry {
	/** `<source>:<dir name>`, the id the include/exclude lists match. */
	id: string;
	/** `project`, `user`, `synced`, or the plugin name. */
	source: string;
	/** Name pi registers (frontmatter `name`, else the directory name). */
	name: string;
	filePath: string;
}

export interface SkillDiscovery {
	skills: SkillEntry[];
	excluded: SkillEntry[];
	diagnostics: Diagnostic[];
}

export interface SkillRoots {
	projectSkillsDir: string | undefined;
	userPlainDirs: readonly string[];
	plugins: readonly Plugin[];
}

const SYNCED_DIR = "synced";

export function discoverSkills(roots: SkillRoots, exclude: readonly string[], parse: ParseFrontmatter): SkillDiscovery {
	const candidates: Array<{ source: string; dir: string }> = [
		...(roots.projectSkillsDir ? childDirs(roots.projectSkillsDir).map((dir) => ({ source: "project", dir })) : []),
		...roots.userPlainDirs.filter((dir) => path.basename(dir) !== SYNCED_DIR).map((dir) => ({ source: "user", dir })),
		...roots.plugins.flatMap((plugin) => pluginSkillDirs(plugin).map((dir) => ({ source: plugin.name, dir }))),
		...roots.userPlainDirs
			.filter((dir) => path.basename(dir) === SYNCED_DIR)
			.flatMap((synced) => childDirs(synced).flatMap(childDirs))
			.map((dir) => ({ source: SYNCED_DIR, dir })),
	];

	const skills: SkillEntry[] = [];
	const excluded: SkillEntry[] = [];
	const diagnostics: Diagnostic[] = [];
	const names = new Set<string>();
	for (const { source, dir } of candidates) {
		const filePath = path.join(dir, "SKILL.md");
		if (!isFile(filePath)) continue;
		const result = readMarkdown(filePath, parse);
		if (!result.ok) {
			diagnostics.push(result.diagnostic);
			continue;
		}
		if (!stringField(result.doc.frontmatter, "description")) {
			diagnostics.push({ path: filePath, message: "skill has no description, pi will not load it" });
			continue;
		}
		const entry: SkillEntry = {
			id: `${source}:${path.basename(dir)}`,
			source,
			name: stringField(result.doc.frontmatter, "name") ?? path.basename(dir),
			filePath,
		};
		if (matchesAny(entry.id, exclude)) {
			excluded.push(entry);
		} else if (names.has(entry.name)) {
			diagnostics.push({ path: filePath, message: `skill "${entry.name}" already provided by an earlier source` });
		} else {
			names.add(entry.name);
			skills.push(entry);
		}
	}
	return { skills, excluded, diagnostics };
}

/** A manifest skill path is either one skill or a directory of skills. */
function pluginSkillDirs(plugin: Plugin): string[] {
	return plugin.skillPaths.flatMap((p) => (isFile(path.join(p, "SKILL.md")) ? [p] : childDirs(p)));
}

function childDirs(dir: string): string[] {
	return listDir(dir)
		.filter((entry) => !entry.name.startsWith("."))
		.map((entry) => path.join(dir, entry.name))
		.filter(isDirectory)
		.sort();
}

export interface ListedSkill {
	name: string;
	description: string;
	filePath: string;
	disableModelInvocation?: boolean;
}

/** Characters pi spends on one `<skill>` entry besides the description. */
const ENTRY_OVERHEAD = 70;
const MIN_DESCRIPTION = 80;

/**
 * Trim the skill listing to Claude Code's budget: every description capped at
 * `maxDescChars`, then, if the listing is still over `budgetChars`, all
 * descriptions shortened evenly. Returns new objects; the input is untouched.
 */
export function applyListingBudget<T extends ListedSkill>(skills: readonly T[], budgetChars: number, maxDescChars: number): T[] {
	const capped = skills.map((skill) => ({ ...skill, description: truncate(collapse(skill.description), maxDescChars) }));
	const visible = capped.filter((skill) => !skill.disableModelInvocation);
	const total = listingSize(visible);
	if (total <= budgetChars || visible.length === 0) return capped;
	const overhead = visible.reduce((sum, skill) => sum + entryOverhead(skill), 0);
	const perSkill = Math.max(MIN_DESCRIPTION, Math.floor((budgetChars - overhead) / visible.length));
	return capped.map((skill) => (skill.disableModelInvocation ? skill : { ...skill, description: truncate(skill.description, perSkill) }));
}

export function listingSize(skills: readonly ListedSkill[]): number {
	return skills.reduce((sum, skill) => sum + entryOverhead(skill) + skill.description.length, 0);
}

function entryOverhead(skill: ListedSkill): number {
	return ENTRY_OVERHEAD + skill.name.length + skill.filePath.length;
}

function collapse(text: string): string {
	return text.replace(/\s+/g, " ").trim();
}

function truncate(text: string, max: number): string {
	return text.length <= max ? text : `${text.slice(0, Math.max(0, max - 1)).trimEnd()}…`;
}

/** The message pi's own `/skill:name` expansion produces, for the `/name` aliases. */
export function skillInvocation(name: string, filePath: string, body: string, args: string): string {
	const block = `<skill name="${name}" location="${filePath}">\nReferences are relative to ${path.dirname(filePath)}.\n\n${body.trim()}\n</skill>`;
	return args.trim() ? `${block}\n\n${args.trim()}` : block;
}
