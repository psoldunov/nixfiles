/**
 * Path helpers: project root discovery, glob matching for `paths:` rules, and
 * the `*` wildcard used by the include/exclude lists in claude-bridge.json.
 */

import * as fs from "node:fs";
import * as path from "node:path";

export function isDirectory(p: string): boolean {
	try {
		return fs.statSync(p).isDirectory();
	} catch {
		return false;
	}
}

export function isFile(p: string): boolean {
	try {
		return fs.statSync(p).isFile();
	} catch {
		return false;
	}
}

export function realpathOr(p: string): string {
	try {
		return fs.realpathSync(p);
	} catch {
		return path.resolve(p);
	}
}

/** `child` is `parent` or lies below it. Both must be absolute. */
export function isInside(child: string, parent: string): boolean {
	const rel = path.relative(parent, child);
	return rel === "" || (!rel.startsWith("..") && !path.isAbsolute(rel));
}

/**
 * Directories from `cwd` up to the enclosing git root, innermost first. Outside
 * a repository only `cwd` itself counts, so a stray `~/.claude` above an
 * unrelated directory never becomes "the project".
 */
export function projectAncestors(cwd: string): string[] {
	const dirs: string[] = [];
	let dir = path.resolve(cwd);
	while (true) {
		dirs.push(dir);
		if (fs.existsSync(path.join(dir, ".git"))) return dirs;
		const parent = path.dirname(dir);
		if (parent === dir) return [path.resolve(cwd)];
		dir = parent;
	}
}

/** The project's `.claude` directory, never the user's own Claude directory. */
export function findProjectClaudeDir(cwd: string, userClaudeDir: string): string | undefined {
	const userReal = realpathOr(userClaudeDir);
	for (const dir of projectAncestors(cwd)) {
		const candidate = path.join(dir, ".claude");
		if (isDirectory(candidate) && realpathOr(candidate) !== userReal) return candidate;
	}
	return undefined;
}

/**
 * Match a file against Claude Code `paths:` globs. Globs are relative to the
 * project, so a file inside `root` is matched by its relative path; a file
 * outside it by its absolute path without the leading slash, which still lets
 * `**\/*.ts` catch it.
 */
export function matchesAnyGlob(filePath: string, globs: readonly string[], root: string): boolean {
	const absolute = path.resolve(root, filePath);
	const candidate = isInside(absolute, root) ? path.relative(root, absolute) : absolute.replace(/^\/+/, "");
	return globs.some((glob) => path.matchesGlob(candidate, glob));
}

/** `*` matches any run of characters; everything else is literal. */
export function wildcardMatch(value: string, pattern: string): boolean {
	const escaped = pattern.split("*").map((part) => part.replace(/[.+?^${}()|[\]\\]/g, "\\$&"));
	return new RegExp(`^${escaped.join(".*")}$`).test(value);
}

export function matchesAny(value: string, patterns: readonly string[]): boolean {
	return patterns.some((pattern) => wildcardMatch(value, pattern));
}

/** List entries of a directory, following symlinks; an unreadable directory is empty. */
export function listDir(dir: string): fs.Dirent[] {
	try {
		return fs.readdirSync(dir, { withFileTypes: true });
	} catch {
		return [];
	}
}

/** Display a path with `~` for the home directory. */
export function tildify(p: string, home: string): string {
	return p === home || p.startsWith(`${home}/`) ? `~${p.slice(home.length)}` : p;
}
