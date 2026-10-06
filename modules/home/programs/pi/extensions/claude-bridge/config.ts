/**
 * Bridge configuration. nix writes `~/.pi/agent/claude-bridge.json`; every
 * field falls back to the default below, so a missing or partial file still
 * gives a working bridge. Invalid fields are reported and replaced, never fatal.
 */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { type Diagnostic, errorMessage } from "./frontmatter.ts";

export interface BridgeConfig {
	/** Claude Code's user directory. */
	claudeDir: string;
	/** Read the project's `.claude/` (rules, skills, agents, CLAUDE.md), only once pi trusts the project. */
	projectClaude: boolean;
	/** Tools whose results trigger lazy rules and nested CLAUDE.md, like Claude's Read/Edit/Write. */
	lazyTools: string[];
	memory: { enabled: boolean; nested: boolean };
	rules: { enabled: boolean };
	skills: {
		enabled: boolean;
		/** Skill ids (`<source>:<name>`, `*` wildcard) that pi never sees. */
		exclude: string[];
		/** Register `/name` and `/plugin:name` next to pi's own `/skill:name`. */
		aliases: boolean;
	};
	agents: {
		enabled: boolean;
		exclude: string[];
		/** Claude `model:` value (opus, sonnet, haiku, ...) to a pi `provider/id`. Unmapped values inherit the parent model. */
		modelMap: Record<string, string>;
		builtins: boolean;
		descriptionMaxChars: number;
		outputMaxBytes: number;
		/** Subagent nesting limit. 1 means only the top-level session gets the Agent tool. */
		maxDepth: number;
	};
}

export const DEFAULT_CONFIG: BridgeConfig = {
	claudeDir: path.join(os.homedir(), ".claude"),
	projectClaude: true,
	lazyTools: ["read", "edit", "write"],
	memory: { enabled: true, nested: true },
	rules: { enabled: true },
	skills: { enabled: true, exclude: ["context-mode:*", "synced:*"], aliases: true },
	agents: {
		enabled: true,
		exclude: [],
		modelMap: {},
		builtins: true,
		descriptionMaxChars: 400,
		outputMaxBytes: 20 * 1024,
		maxDepth: 1,
	},
};

/** Claude Code's skill-listing budget, read from its own settings for parity. */
export interface SkillListingSettings {
	budgetFraction: number;
	maxDescChars: number;
}

export const DEFAULT_SKILL_LISTING: SkillListingSettings = { budgetFraction: 0.01, maxDescChars: 1024 };

export interface Loaded<T> {
	value: T;
	diagnostics: Diagnostic[];
}

export function loadConfig(filePath: string): Loaded<BridgeConfig> {
	const raw = readJson(filePath);
	if (!raw.ok) return { value: DEFAULT_CONFIG, diagnostics: raw.missing ? [] : [raw.diagnostic] };
	return parseConfig(raw.value, filePath);
}

export function parseConfig(input: unknown, source: string): Loaded<BridgeConfig> {
	const diagnostics: Diagnostic[] = [];
	const obj = asObject(input);
	const pick = <T>(value: unknown, fallback: T, key: string, valid: (v: unknown) => boolean): T => {
		if (value === undefined) return fallback;
		if (valid(value)) return value as T;
		diagnostics.push({ path: source, message: `invalid "${key}", using default` });
		return fallback;
	};
	const d = DEFAULT_CONFIG;
	const memory = asObject(obj.memory);
	const rules = asObject(obj.rules);
	const skills = asObject(obj.skills);
	const agents = asObject(obj.agents);
	const value: BridgeConfig = {
		claudeDir: expandHome(pick(obj.claudeDir, d.claudeDir, "claudeDir", isNonEmptyString)),
		projectClaude: pick(obj.projectClaude, d.projectClaude, "projectClaude", isBoolean),
		lazyTools: pick(obj.lazyTools, d.lazyTools, "lazyTools", isStringArray),
		memory: {
			enabled: pick(memory.enabled, d.memory.enabled, "memory.enabled", isBoolean),
			nested: pick(memory.nested, d.memory.nested, "memory.nested", isBoolean),
		},
		rules: { enabled: pick(rules.enabled, d.rules.enabled, "rules.enabled", isBoolean) },
		skills: {
			enabled: pick(skills.enabled, d.skills.enabled, "skills.enabled", isBoolean),
			exclude: pick(skills.exclude, d.skills.exclude, "skills.exclude", isStringArray),
			aliases: pick(skills.aliases, d.skills.aliases, "skills.aliases", isBoolean),
		},
		agents: {
			enabled: pick(agents.enabled, d.agents.enabled, "agents.enabled", isBoolean),
			exclude: pick(agents.exclude, d.agents.exclude, "agents.exclude", isStringArray),
			modelMap: pick(agents.modelMap, d.agents.modelMap, "agents.modelMap", isStringRecord),
			builtins: pick(agents.builtins, d.agents.builtins, "agents.builtins", isBoolean),
			descriptionMaxChars: pick(agents.descriptionMaxChars, d.agents.descriptionMaxChars, "agents.descriptionMaxChars", isPositiveInt),
			outputMaxBytes: pick(agents.outputMaxBytes, d.agents.outputMaxBytes, "agents.outputMaxBytes", isPositiveInt),
			maxDepth: pick(agents.maxDepth, d.agents.maxDepth, "agents.maxDepth", isNonNegativeInt),
		},
	};
	return { value, diagnostics };
}

export function loadSkillListingSettings(claudeSettingsPath: string): Loaded<SkillListingSettings> {
	const raw = readJson(claudeSettingsPath);
	if (!raw.ok) return { value: DEFAULT_SKILL_LISTING, diagnostics: raw.missing ? [] : [raw.diagnostic] };
	const obj = asObject(raw.value);
	const fraction = obj.skillListingBudgetFraction;
	const maxDesc = obj.skillListingMaxDescChars;
	return {
		value: {
			budgetFraction: typeof fraction === "number" && fraction > 0 && fraction <= 1 ? fraction : DEFAULT_SKILL_LISTING.budgetFraction,
			maxDescChars: isPositiveInt(maxDesc) ? (maxDesc as number) : DEFAULT_SKILL_LISTING.maxDescChars,
		},
		diagnostics: [],
	};
}

type JsonRead = { ok: true; value: unknown } | { ok: false; missing: boolean; diagnostic: Diagnostic };

function readJson(filePath: string): JsonRead {
	let text: string;
	try {
		text = fs.readFileSync(filePath, "utf-8");
	} catch (error) {
		const missing = (error as NodeJS.ErrnoException).code === "ENOENT";
		return { ok: false, missing, diagnostic: { path: filePath, message: errorMessage(error, "cannot read") } };
	}
	try {
		return { ok: true, value: JSON.parse(text) };
	} catch (error) {
		return { ok: false, missing: false, diagnostic: { path: filePath, message: errorMessage(error, "invalid JSON") } };
	}
}

export function expandHome(p: string): string {
	return p === "~" || p.startsWith("~/") ? path.join(os.homedir(), p.slice(1)) : p;
}

function asObject(value: unknown): Record<string, unknown> {
	return value !== null && typeof value === "object" && !Array.isArray(value) ? (value as Record<string, unknown>) : {};
}

const isBoolean = (v: unknown) => typeof v === "boolean";
const isNonEmptyString = (v: unknown) => typeof v === "string" && v.trim() !== "";
const isStringArray = (v: unknown) => Array.isArray(v) && v.every((item) => typeof item === "string");
const isPositiveInt = (v: unknown) => Number.isInteger(v) && (v as number) > 0;
const isNonNegativeInt = (v: unknown) => Number.isInteger(v) && (v as number) >= 0;
const isStringRecord = (v: unknown) =>
	v !== null && typeof v === "object" && !Array.isArray(v) && Object.values(v).every((item) => typeof item === "string");
