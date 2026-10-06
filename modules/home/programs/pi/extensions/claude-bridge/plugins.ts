/**
 * Claude Code plugins linked into `<claude dir>/skills/<plugin>/` (how the nix
 * module installs context-mode, caveman, impeccable, taste-skill, ...).
 *
 * A plugin is a directory with `.claude-plugin/plugin.json`. Its manifest may
 * name `skills` and `agents` paths (string or list); without them Claude Code
 * uses `./skills/` and `./agents/`. Only those paths count: a blind recursive
 * scan would also pick up vendored copies such as `caveman/plugins/**` and
 * `context-mode/configs/**`, which is how pi ends up listing 75 skills.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import { type Diagnostic, errorMessage } from "./frontmatter.ts";
import { isDirectory, listDir } from "./paths.ts";

export interface Plugin {
	name: string;
	root: string;
	skillPaths: string[];
	agentPaths: string[];
}

export interface PluginScan {
	plugins: Plugin[];
	/** Directories under the skills dir that are not plugins. */
	plainDirs: string[];
	diagnostics: Diagnostic[];
}

export function scanSkillsDir(skillsDir: string): PluginScan {
	const plugins: Plugin[] = [];
	const plainDirs: string[] = [];
	const diagnostics: Diagnostic[] = [];
	for (const entry of listDir(skillsDir)) {
		if (entry.name.startsWith(".")) continue;
		const dir = path.join(skillsDir, entry.name);
		if (!isDirectory(dir)) continue;
		const manifestPath = path.join(dir, ".claude-plugin", "plugin.json");
		if (!fs.existsSync(manifestPath)) {
			plainDirs.push(dir);
			continue;
		}
		const parsed = readManifest(manifestPath);
		if (!parsed.ok) {
			diagnostics.push(parsed.diagnostic);
			continue;
		}
		const manifest = parsed.value;
		plugins.push({
			name: typeof manifest.name === "string" && manifest.name !== "" ? manifest.name : entry.name,
			root: dir,
			skillPaths: manifestPaths(dir, manifest.skills, "skills"),
			agentPaths: manifestPaths(dir, manifest.agents, "agents"),
		});
	}
	return { plugins, plainDirs: plainDirs.sort(), diagnostics };
}

function manifestPaths(root: string, value: unknown, fallback: string): string[] {
	const declared = Array.isArray(value) ? value : typeof value === "string" ? [value] : [];
	const relative = declared.filter((item): item is string => typeof item === "string");
	const candidates = relative.length > 0 ? relative : [fallback];
	return candidates.map((rel) => path.resolve(root, rel)).filter((p) => isInsideOrEqual(p, root) && fs.existsSync(p));
}

function isInsideOrEqual(child: string, parent: string): boolean {
	const rel = path.relative(parent, child);
	return !rel.startsWith("..") && !path.isAbsolute(rel);
}

type ManifestRead = { ok: true; value: Record<string, unknown> } | { ok: false; diagnostic: Diagnostic };

function readManifest(manifestPath: string): ManifestRead {
	try {
		const value = JSON.parse(fs.readFileSync(manifestPath, "utf-8"));
		if (value === null || typeof value !== "object" || Array.isArray(value)) {
			return { ok: false, diagnostic: { path: manifestPath, message: "plugin manifest is not an object" } };
		}
		return { ok: true, value };
	} catch (error) {
		return { ok: false, diagnostic: { path: manifestPath, message: errorMessage(error, "invalid plugin manifest") } };
	}
}
