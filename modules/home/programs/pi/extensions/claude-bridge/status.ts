/** Text for the `/claude-bridge` command: what pi got from Claude Code, and why not the rest. */

import * as os from "node:os";
import type { Discovery } from "./discovery.ts";
import { tildify } from "./paths.ts";

export interface StatusExtras {
	alwaysMemory: readonly string[];
	injectedKeys: readonly string[];
	listingChars: number;
	budgetChars: number;
	agentToolActive: boolean;
}

export function formatStatus(discovery: Discovery, extras: StatusExtras): string {
	const home = os.homedir();
	const t = (p: string) => tildify(p, home);
	const { rules, skills, agents } = discovery;
	const bySource = countBy(skills.skills.map((skill) => skill.source));
	const lines = [
		`claude-bridge for ${t(discovery.cwd)}`,
		`Project .claude: ${discovery.projectClaudeDir ? t(discovery.projectClaudeDir) : discovery.trusted ? "none" : "skipped (project not trusted)"}`,
		`CLAUDE.md always loaded: ${extras.alwaysMemory.map(t).join(", ") || "none"}`,
		`Rules: ${rules.always.length} always-on, ${rules.scoped.length} path-scoped (${rules.scoped.map((rule) => rule.id).join(", ") || "none"})`,
		`Skills: ${skills.skills.length} (${Object.entries(bySource).map(([source, n]) => `${source} ${n}`).join(", ") || "none"})`,
		`Skills excluded: ${skills.excluded.map((skill) => skill.id).join(", ") || "none"}`,
		extras.budgetChars > 0
			? `Skill listing: ${extras.listingChars} chars, budget ${extras.budgetChars}`
			: "Skill listing: measured at the first prompt",
		`Agents: ${agents.agents.length}${extras.agentToolActive ? "" : " (Agent tool inactive here)"}: ${agents.agents.map((agent) => agent.name).join(", ") || "none"}`,
		`Injected in this branch: ${extras.injectedKeys.join(", ") || "nothing yet"}`,
	];
	if (discovery.diagnostics.length > 0) {
		lines.push("Warnings:", ...discovery.diagnostics.map((d) => `  ${t(d.path)}: ${d.message}`));
	}
	return lines.join("\n");
}

function countBy(values: readonly string[]): Record<string, number> {
	return values.reduce<Record<string, number>>((acc, value) => ({ ...acc, [value]: (acc[value] ?? 0) + 1 }), {});
}
