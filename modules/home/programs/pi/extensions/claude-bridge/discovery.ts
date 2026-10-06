/**
 * One pass over Claude Code's directories for a working directory: rules,
 * skills, agents and the project `.claude/` they may come from. Pure apart from
 * file reads, so the status command and the tests see exactly what pi gets.
 */

import * as path from "node:path";
import { type AgentDiscovery, discoverAgents } from "./agents.ts";
import type { BridgeConfig } from "./config.ts";
import type { Diagnostic, ParseFrontmatter } from "./frontmatter.ts";
import { findProjectClaudeDir } from "./paths.ts";
import { scanSkillsDir } from "./plugins.ts";
import { discoverRules, type RuleRoot, type RuleSet } from "./rules.ts";
import { discoverSkills, type SkillDiscovery } from "./skills.ts";

export interface Discovery {
	cwd: string;
	trusted: boolean;
	projectClaudeDir: string | undefined;
	rules: RuleSet;
	skills: SkillDiscovery;
	agents: AgentDiscovery;
	diagnostics: Diagnostic[];
}

const EMPTY_RULES: RuleSet = { always: [], scoped: [], diagnostics: [] };
const EMPTY_SKILLS: SkillDiscovery = { skills: [], excluded: [], diagnostics: [] };
const EMPTY_AGENTS: AgentDiscovery = { agents: [], diagnostics: [] };

export function discover(config: BridgeConfig, cwd: string, trusted: boolean, parse: ParseFrontmatter): Discovery {
	const projectClaudeDir = config.projectClaude && trusted ? findProjectClaudeDir(cwd, config.claudeDir) : undefined;
	const scan = scanSkillsDir(path.join(config.claudeDir, "skills"));

	const ruleRoots: RuleRoot[] = [
		{ source: "user", dir: path.join(config.claudeDir, "rules") },
		...(projectClaudeDir ? [{ source: "project" as const, dir: path.join(projectClaudeDir, "rules") }] : []),
	];
	const rules = config.rules.enabled ? discoverRules(ruleRoots, parse) : EMPTY_RULES;

	const skills = config.skills.enabled
		? discoverSkills(
				{
					projectSkillsDir: projectClaudeDir ? path.join(projectClaudeDir, "skills") : undefined,
					userPlainDirs: scan.plainDirs,
					plugins: scan.plugins,
				},
				config.skills.exclude,
				parse,
			)
		: EMPTY_SKILLS;

	const agents = config.agents.enabled
		? discoverAgents(
				{
					projectAgentsDir: projectClaudeDir ? path.join(projectClaudeDir, "agents") : undefined,
					userAgentsDir: path.join(config.claudeDir, "agents"),
					plugins: scan.plugins,
					builtins: config.agents.builtins,
				},
				config.agents.exclude,
				parse,
			)
		: EMPTY_AGENTS;

	return {
		cwd,
		trusted,
		projectClaudeDir,
		rules,
		skills,
		agents,
		diagnostics: [...scan.diagnostics, ...rules.diagnostics, ...skills.diagnostics, ...agents.diagnostics],
	};
}
