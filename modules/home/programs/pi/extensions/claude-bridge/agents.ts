/**
 * Claude Code subagents: `<claude dir>/agents/*.md`, plugin agent paths,
 * the project's `.claude/agents/*.md`, plus Claude Code's built-in
 * general-purpose, Explore and Plan types.
 *
 * Only name and description reach the parent model (in the Agent tool's
 * description). The body becomes the child process's system prompt, so it
 * never enters the parent context.
 */

import * as path from "node:path";
import { type Diagnostic, type ParseFrontmatter, readMarkdown, stringField, toStringList } from "./frontmatter.ts";
import { isFile, listDir, matchesAny } from "./paths.ts";
import type { Plugin } from "./plugins.ts";

export interface AgentDefinition {
	/** `subagent_type` value. Plugin agents are namespaced like Claude Code: `caveman:cavecrew-builder`. */
	name: string;
	description: string;
	source: string;
	/** Claude tool names as written in frontmatter; empty means the default tool set. */
	tools: string[];
	disallowedTools: string[];
	/** Raw Claude `model:` value, if any. */
	model: string | undefined;
	systemPrompt: string;
	filePath: string | undefined;
}

export interface AgentDiscovery {
	agents: AgentDefinition[];
	diagnostics: Diagnostic[];
}

export interface AgentRoots {
	projectAgentsDir: string | undefined;
	userAgentsDir: string;
	plugins: readonly Plugin[];
	builtins: boolean;
}

export function discoverAgents(roots: AgentRoots, exclude: readonly string[], parse: ParseFrontmatter): AgentDiscovery {
	const diagnostics: Diagnostic[] = [];
	const sources: Array<{ source: string; prefix: string; dir: string }> = [
		...(roots.projectAgentsDir ? [{ source: "project", prefix: "", dir: roots.projectAgentsDir }] : []),
		{ source: "user", prefix: "", dir: roots.userAgentsDir },
		...roots.plugins.flatMap((plugin) => plugin.agentPaths.map((dir) => ({ source: plugin.name, prefix: `${plugin.name}:`, dir }))),
	];
	const byName = new Map<string, AgentDefinition>();
	for (const { source, prefix, dir } of sources) {
		for (const filePath of agentFiles(dir)) {
			const agent = readAgent(filePath, source, prefix, parse);
			if (!agent.ok) {
				if (agent.diagnostic) diagnostics.push(agent.diagnostic);
				continue;
			}
			if (!byName.has(agent.value.name)) byName.set(agent.value.name, agent.value);
		}
	}
	if (roots.builtins) {
		for (const builtin of BUILTIN_AGENTS) if (!byName.has(builtin.name)) byName.set(builtin.name, builtin);
	}
	const agents = [...byName.values()].filter((agent) => !matchesAny(agent.name, exclude));
	return { agents, diagnostics };
}

function agentFiles(dir: string): string[] {
	return listDir(dir)
		.filter((entry) => entry.name.endsWith(".md") && !entry.name.startsWith("."))
		.map((entry) => path.join(dir, entry.name))
		.filter(isFile)
		.sort();
}

type AgentRead = { ok: true; value: AgentDefinition } | { ok: false; diagnostic?: Diagnostic };

function readAgent(filePath: string, source: string, prefix: string, parse: ParseFrontmatter): AgentRead {
	const result = readMarkdown(filePath, parse);
	if (!result.ok) return { ok: false, diagnostic: result.diagnostic };
	const fm = result.doc.frontmatter;
	const name = stringField(fm, "name");
	const description = stringField(fm, "description");
	// Plugin agent directories also hold READMEs and docs; only files that
	// declare both fields are agents, as in Claude Code.
	if (!name || !description) return { ok: false };
	return {
		ok: true,
		value: {
			name: `${prefix}${name}`,
			description,
			source,
			tools: toStringList(fm.tools),
			disallowedTools: toStringList(fm.disallowedTools),
			model: stringField(fm, "model"),
			systemPrompt: result.doc.body.trim(),
			filePath,
		},
	};
}

const READ_ONLY_TOOLS = ["Read", "Grep", "Glob", "LS", "Bash"];

export const BUILTIN_AGENTS: readonly AgentDefinition[] = [
	{
		name: "general-purpose",
		description:
			"General-purpose agent for researching complex questions, searching for code, and executing multi-step tasks. Use it when a search or task needs several rounds of reading and acting.",
		source: "builtin",
		tools: [],
		disallowedTools: [],
		model: undefined,
		systemPrompt:
			"You are a general-purpose agent. Complete the task fully: search, read, and change code as needed. Do not gold-plate. When done, report what you did and what you found, with file paths.",
		filePath: undefined,
	},
	{
		name: "Explore",
		description:
			'Fast read-only agent for exploring codebases: find files by pattern, search code for keywords, answer questions about how the code works. Say how thorough to be: "quick", "medium", or "very thorough".',
		source: "builtin",
		tools: READ_ONLY_TOOLS,
		disallowedTools: [],
		model: undefined,
		systemPrompt:
			"You are a read-only codebase explorer. Never create, modify, or delete files; use bash only for read-only commands. Search broadly, then read the relevant sections. Report findings concisely with absolute file paths and line numbers.",
		filePath: undefined,
	},
	{
		name: "Plan",
		description:
			"Read-only software architect agent for designing implementation plans. Returns step-by-step plans, identifies critical files, and weighs architectural trade-offs.",
		source: "builtin",
		tools: READ_ONLY_TOOLS,
		disallowedTools: [],
		model: undefined,
		systemPrompt:
			"You are a read-only software architect. Never create, modify, or delete files. Explore the code the task touches, then return a concrete implementation plan: the approach, the critical files with paths, the sequence of changes, risks, and how to verify.",
		filePath: undefined,
	},
];

/** Claude Code tool name to pi tool name. Unlisted tools have no pi counterpart. */
const TOOL_MAP: Readonly<Record<string, string>> = {
	Read: "read",
	Write: "write",
	Edit: "edit",
	MultiEdit: "edit",
	Bash: "bash",
	Grep: "grep",
	Glob: "find",
	LS: "ls",
};

const PI_TOOLS = new Set(["read", "write", "edit", "bash", "grep", "find", "ls"]);
export const PI_DEFAULT_TOOLS: readonly string[] = ["read", "bash", "edit", "write"];

export interface ToolMapping {
	/** `undefined` means "pi's default tools"; `[]` means "no tools". */
	tools: string[] | undefined;
	dropped: string[];
}

export function mapTools(claudeTools: readonly string[], disallowed: readonly string[]): ToolMapping {
	const dropped: string[] = [];
	const toPi = (name: string): string | undefined => {
		const mapped = TOOL_MAP[name] ?? (PI_TOOLS.has(name) ? name : undefined);
		if (!mapped) dropped.push(name);
		return mapped;
	};
	const denied = new Set(disallowed.map((name) => TOOL_MAP[name] ?? name));
	const wantsAll = claudeTools.length === 0 || claudeTools.includes("*");
	if (wantsAll && denied.size === 0) return { tools: undefined, dropped };
	const base = wantsAll ? [...PI_DEFAULT_TOOLS] : claudeTools.map(toPi).filter((name): name is string => !!name);
	const tools = [...new Set(base)].filter((name) => !denied.has(name));
	return { tools, dropped: [...new Set(dropped)] };
}

/** A mapped tier wins; anything else (including `inherit`) runs on the parent's model. */
export function resolveModel(claudeModel: string | undefined, modelMap: Readonly<Record<string, string>>, parent: string | undefined): string | undefined {
	if (claudeModel && modelMap[claudeModel]) return modelMap[claudeModel];
	return parent;
}

export function formatAgentCatalog(agents: readonly AgentDefinition[], maxDescription: number): string {
	return agents
		.map((agent) => {
			const description = agent.description.replace(/\s+/g, " ").trim();
			const short = description.length > maxDescription ? `${description.slice(0, maxDescription - 1).trimEnd()}…` : description;
			const { tools } = mapTools(agent.tools, agent.disallowedTools);
			return `- ${agent.name}: ${short} (Tools: ${tools ? tools.join(", ") || "none" : "all default tools"})`;
		})
		.join("\n");
}
