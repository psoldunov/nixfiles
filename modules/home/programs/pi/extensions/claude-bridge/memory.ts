/**
 * Claude Code memory files (CLAUDE.md).
 *
 * pi already loads `CLAUDE.md` from the working directory and its ancestors.
 * Claude Code additionally loads, and the bridge adds:
 *   - always: `<claude dir>/CLAUDE.md`, `CLAUDE.local.md` up to the git root,
 *     and the project's `.claude/CLAUDE.md` (only once the project is trusted);
 *   - lazily: `CLAUDE.md` in a subdirectory of the working directory, the first
 *     time a file below that subdirectory is read or edited.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import { isFile, isInside, projectAncestors, realpathOr } from "./paths.ts";

export interface MemoryFile {
	path: string;
	content: string;
}

export interface AlwaysMemoryInput {
	claudeDir: string;
	cwd: string;
	projectClaudeDir: string | undefined;
	/** Paths pi already put in the prompt, so nothing is loaded twice. */
	existing: readonly string[];
}

export function alwaysMemoryFiles(input: AlwaysMemoryInput): MemoryFile[] {
	const ancestorsOutermostFirst = [...projectAncestors(input.cwd)].reverse();
	const candidates = [
		path.join(input.claudeDir, "CLAUDE.md"),
		...(input.projectClaudeDir ? [path.join(input.projectClaudeDir, "CLAUDE.md")] : []),
		...ancestorsOutermostFirst.map((dir) => path.join(dir, "CLAUDE.local.md")),
	];
	const seen = new Set(input.existing.map(realpathOr));
	const files: MemoryFile[] = [];
	for (const candidate of candidates) {
		const real = realpathOr(candidate);
		if (seen.has(real) || !isFile(candidate)) continue;
		seen.add(real);
		const content = readText(candidate);
		if (content !== undefined && content.trim() !== "") files.push({ path: candidate, content: content.trim() });
	}
	return files;
}

/**
 * `CLAUDE.md` files that apply to `filePath` but sit below `cwd`, outermost
 * first. Files outside the working directory pull in nothing, as in Claude Code.
 */
export function nestedMemoryPaths(filePath: string, cwd: string): string[] {
	const root = path.resolve(cwd);
	const absolute = path.resolve(root, filePath);
	if (!isInside(absolute, root)) return [];
	const found: string[] = [];
	let dir = path.dirname(absolute);
	while (dir !== root && isInside(dir, root)) {
		const candidate = path.join(dir, "CLAUDE.md");
		if (isFile(candidate)) found.push(candidate);
		dir = path.dirname(dir);
	}
	return found.reverse();
}

export function memoryMarker(filePath: string): string {
	return `<claude-memory id="${filePath}"`;
}

export function renderNestedMemory(file: MemoryFile): string {
	return [
		`${memoryMarker(file.path)}>`,
		`Instructions from ${file.path}. They apply to work on files under ${path.dirname(file.path)}.`,
		"",
		file.content,
		"</claude-memory>",
	].join("\n");
}

export function readText(filePath: string): string | undefined {
	try {
		return fs.readFileSync(filePath, "utf-8");
	} catch {
		return undefined;
	}
}
