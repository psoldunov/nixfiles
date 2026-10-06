/**
 * claude-bridge: Claude Code's memory, rules, skills and subagents in pi, each
 * loaded at the moment Claude Code would load it.
 *
 *   CLAUDE.md (user, project .claude/, CLAUDE.local.md)  -> prompt context files
 *   nested CLAUDE.md below the working directory          -> first touched file under it
 *   rules without `paths:`                               -> `claude_rules` prompt section
 *   rules with `paths:`                                  -> first matching read/edit/write
 *   skills                                               -> pi's skill listing, budget-trimmed
 *   agents                                               -> `Agent` tool, body only in the child
 *
 * Configuration: `~/.pi/agent/claude-bridge.json`, written by nix
 * (modules/home/programs/pi). `/claude-bridge` shows what was loaded.
 */

import * as path from "node:path";
import {
	type ExtensionAPI,
	type ExtensionContext,
	getAgentDir,
	parseFrontmatter,
	stripFrontmatter,
} from "@earendil-works/pi-coding-agent";
import { currentDepth, registerAgentTool } from "./agent-tool.ts";
import { expandHome, loadConfig, loadSkillListingSettings } from "./config.ts";
import { type Discovery, discover } from "./discovery.ts";
import type { ParseFrontmatter } from "./frontmatter.ts";
import { collectMarkers, planInjection } from "./inject.ts";
import { projectAncestors } from "./paths.ts";
import { alwaysMemoryFiles, readText } from "./memory.ts";
import { renderAlwaysSection } from "./rules.ts";
import { applyListingBudget, listingSize, type SkillEntry, skillInvocation } from "./skills.ts";
import { formatStatus } from "./status.ts";

const parse: ParseFrontmatter = (content) => parseFrontmatter<Record<string, unknown>>(content);

/** pi's built-in slash commands; a skill alias never shadows one. */
const BUILTIN_COMMANDS = new Set([
	"settings", "model", "tree", "thinking", "scoped-models", "export", "import", "share", "bug", "copy", "name",
	"session", "changelog", "hotkeys", "fork", "clone", "trust", "login", "logout", "new", "compact", "resume",
	"reload", "quit", "claude-bridge",
]);
const NON_PLUGIN_SOURCES = new Set(["user", "project", "synced"]);
const DEFAULT_CONTEXT_WINDOW = 200_000;
const CHARS_PER_TOKEN = 4;

export default function claudeBridge(pi: ExtensionAPI) {
	const configLoad = loadConfig(path.join(getAgentDir(), "claude-bridge.json"));
	const config = configLoad.value;
	const listing = loadSkillListingSettings(path.join(config.claudeDir, "settings.json"));
	const loadDiagnostics = [...configLoad.diagnostics, ...listing.diagnostics];

	/** Lazy blocks injected during the current turn, before they reach the session. */
	const inflight = new Set<string>();
	const aliases = new Set<string>();
	let discovery: Discovery | undefined;
	let lastListing = { chars: 0, budget: 0 };
	let agentToolActive = false;

	const refresh = (ctx: ExtensionContext): Discovery => {
		const found = discover(config, ctx.cwd, isTrusted(ctx), parse);
		discovery = { ...found, diagnostics: [...loadDiagnostics, ...found.diagnostics] };
		return discovery;
	};
	const current = (ctx: ExtensionContext): Discovery =>
		discovery && discovery.cwd === ctx.cwd && discovery.trusted === isTrusted(ctx) ? discovery : refresh(ctx);

	pi.on("resources_discover", (_event, ctx) => ({ skillPaths: refresh(ctx).skills.skills.map((skill) => skill.filePath) }));

	pi.on("session_start", (event, ctx) => {
		inflight.clear();
		const found = current(ctx);
		if (!agentToolActive && config.agents.enabled && found.agents.agents.length > 0 && currentDepth() < config.agents.maxDepth) {
			registerAgentTool(pi, found.agents.agents, config.agents);
			agentToolActive = true;
		}
		if (config.skills.aliases) registerSkillAliases(found.skills.skills);
		if (ctx.hasUI && (event.reason === "startup" || event.reason === "reload") && found.diagnostics.length > 0) {
			ctx.ui.notify(`claude-bridge: ${found.diagnostics.length} warning(s). Run /claude-bridge for details.`, "warning");
		}
	});

	pi.on("before_agent_start", (event, ctx) => {
		const found = current(ctx);
		const options = event.systemPromptOptions;
		if (config.memory.enabled) {
			const memory = alwaysMemoryFiles({
				claudeDir: config.claudeDir,
				cwd: ctx.cwd,
				projectClaudeDir: found.projectClaudeDir,
				existing: options.contextFiles.map((file) => file.path),
			});
			options.contextFiles = [...options.contextFiles, ...memory];
		}
		const rules = renderAlwaysSection(found.rules.always);
		if (rules) options.sections = { ...options.sections, claude_rules: rules };
		const budget = Math.floor((ctx.model?.contextWindow ?? DEFAULT_CONTEXT_WINDOW) * listing.value.budgetFraction * CHARS_PER_TOKEN);
		options.skills = applyListingBudget(options.skills, budget, listing.value.maxDescChars);
		lastListing = { chars: listingSize(options.skills.filter((skill) => !skill.disableModelInvocation)), budget };
	});

	pi.on("tool_result", (event, ctx) => {
		if (!config.lazyTools.includes(event.toolName) || event.isError || event.parentToolCallId) return;
		const rawPath = event.input.path;
		if (typeof rawPath !== "string" || rawPath.trim() === "") return;
		const found = current(ctx);
		const nestedMemory = config.memory.enabled && config.memory.nested;
		if (found.rules.scoped.length === 0 && !nestedMemory) return;
		const projectRoot = projectAncestors(ctx.cwd).at(-1) ?? ctx.cwd;
		const plan = (skip: ReadonlySet<string>) =>
			planInjection({
				filePath: expandHome(rawPath.replace(/^@/, "")),
				cwd: ctx.cwd,
				projectRoot,
				scopedRules: found.rules.scoped,
				nestedMemory,
				skip,
			});
		// Scan the context only when something would be injected at all.
		if (!plan(inflight)) return;
		const injection = plan(new Set([...collectMarkers(contextMessages(ctx)), ...inflight]));
		if (!injection) return;
		for (const key of injection.keys) inflight.add(key);
		return {
			content: [...event.content, { type: "text" as const, text: injection.text }],
			...(event.structuredContent !== undefined ? { structuredContent: event.structuredContent } : {}),
		};
	});

	pi.on("turn_end", () => inflight.clear());
	pi.on("session_compact", () => inflight.clear());
	pi.on("session_tree", () => inflight.clear());

	pi.registerCommand("claude-bridge", {
		description: "Show what claude-bridge loaded from Claude Code",
		handler: async (_args, ctx) => {
			const found = current(ctx);
			const alwaysMemory = config.memory.enabled
				? alwaysMemoryFiles({ claudeDir: config.claudeDir, cwd: ctx.cwd, projectClaudeDir: found.projectClaudeDir, existing: [] })
				: [];
			const status = formatStatus(found, {
				alwaysMemory: alwaysMemory.map((file) => file.path),
				injectedKeys: [...collectMarkers(contextMessages(ctx))],
				listingChars: lastListing.chars,
				budgetChars: lastListing.budget,
				agentToolActive,
			});
			ctx.ui.notify(status, "info");
		},
	});

	function registerSkillAliases(skills: readonly SkillEntry[]): void {
		const taken = new Set(pi.getCommands().map((command) => command.name).filter((name) => !aliases.has(name)));
		for (const skill of skills) {
			const names = NON_PLUGIN_SOURCES.has(skill.source) ? [skill.name] : [skill.name, `${skill.source}:${skill.name}`];
			for (const name of names) {
				if (BUILTIN_COMMANDS.has(name) || taken.has(name)) continue;
				taken.add(name);
				aliases.add(name);
				pi.registerCommand(name, {
					description: `Claude Code skill ${skill.id}`,
					handler: async (args, ctx) => invokeSkill(skill, args, ctx),
				});
			}
		}
	}

	async function invokeSkill(skill: SkillEntry, args: string, ctx: ExtensionContext): Promise<void> {
		const content = readText(skill.filePath);
		if (content === undefined) {
			ctx.ui.notify(`claude-bridge: cannot read ${skill.filePath}`, "error");
			return;
		}
		const message = skillInvocation(skill.name, skill.filePath, stripFrontmatter(content), args);
		await pi.sendUserMessage(message, ctx.isIdle() ? undefined : { deliverAs: "followUp" });
	}
}

function isTrusted(ctx: ExtensionContext): boolean {
	try {
		return ctx.isProjectTrusted();
	} catch {
		return false;
	}
}

/** The compaction-aware entries the model currently sees, as message-like objects. */
function contextMessages(ctx: ExtensionContext): unknown[] {
	try {
		return ctx.sessionManager.buildContextEntries().map((entry) => ("message" in entry ? entry.message : entry));
	} catch {
		return [];
	}
}
