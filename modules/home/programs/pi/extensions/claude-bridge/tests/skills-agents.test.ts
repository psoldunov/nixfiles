import assert from "node:assert/strict";
import * as path from "node:path";
import { after, describe, it } from "node:test";
import { BUILTIN_AGENTS, discoverAgents, formatAgentCatalog, mapTools, resolveModel } from "../agents.ts";
import { DEFAULT_CONFIG } from "../config.ts";
import { discover } from "../discovery.ts";
import { scanSkillsDir } from "../plugins.ts";
import { applyListingBudget, discoverSkills, skillInvocation } from "../skills.ts";
import { makeTree, md, parseFixture, removeTree } from "./helpers.ts";

const trees: string[] = [];
const tree = (files: Record<string, string>) => {
	const root = makeTree(files);
	trees.push(root);
	return root;
};
after(() => trees.forEach(removeTree));

const skill = (name: string, description = `${name} does things`) => md(`name: ${name}\ndescription: ${description}`, `# ${name}\nBody.\n`);
const agent = (name: string, extra = "") => md(`name: ${name}\ndescription: ${name} agent\n${extra}`, `You are ${name}.\n`);

/** A ~/.claude shaped like the nix-managed one, plus the traps pi's recursive scan falls into. */
const claudeTree = {
	"claude/skills/code-review/SKILL.md": skill("code-review"),
	"claude/skills/humanizer/SKILL.md": skill("humanizer"),
	"claude/skills/no-description/SKILL.md": md("name: no-description", "body"),
	"claude/skills/.trash/old/SKILL.md": skill("old"),
	"claude/skills/caveman/.claude-plugin/plugin.json": JSON.stringify({ name: "caveman" }),
	"claude/skills/caveman/skills/caveman/SKILL.md": skill("caveman"),
	"claude/skills/caveman/skills/cavecrew/SKILL.md": skill("cavecrew"),
	"claude/skills/caveman/plugins/caveman/skills/caveman/SKILL.md": skill("caveman", "vendored duplicate"),
	"claude/skills/caveman/agents/cavecrew-builder.md": agent("cavecrew-builder", 'tools: ["Read", "Edit", "WebFetch"]'),
	"claude/skills/caveman/agents/README.md": "# not an agent\n",
	"claude/skills/context-mode/.claude-plugin/plugin.json": JSON.stringify({ name: "context-mode", skills: "./skills/" }),
	"claude/skills/context-mode/skills/ctx-stats/SKILL.md": skill("ctx-stats"),
	"claude/skills/context-mode/configs/copilot/skills/context-mode/SKILL.md": skill("context-mode"),
	"claude/skills/single/.claude-plugin/plugin.json": JSON.stringify({ name: "single", skills: ["./only"] }),
	"claude/skills/single/only/SKILL.md": skill("only-skill"),
	"claude/skills/synced/bucket-1/docx/SKILL.md": skill("docx"),
	"claude/agents/planner.md": agent("planner", "tools: Read, Grep, Glob\nmodel: opus"),
	"claude/agents/broken.md": md("description: missing name", "x"),
	"claude/rules/common/a.md": "always\n",
	"repo/.git/HEAD": "",
	"repo/.claude/skills/humanizer/SKILL.md": skill("humanizer", "project humanizer"),
	"repo/.claude/agents/planner.md": agent("planner", "model: sonnet"),
	"repo/.claude/rules/p.md": md('paths:\n  - "**/*.py"', "python rule\n"),
};

describe("skills", () => {
	it("finds skills the Claude Code way: no vendored copies, dot dirs, or description-less skills", () => {
		const root = tree(claudeTree);
		const scan = scanSkillsDir(path.join(root, "claude/skills"));
		assert.deepEqual(scan.plugins.map((p) => p.name).sort(), ["caveman", "context-mode", "single"]);
		const found = discoverSkills({ projectSkillsDir: undefined, userPlainDirs: scan.plainDirs, plugins: scan.plugins }, ["context-mode:*", "synced:*"], parseFixture);
		assert.deepEqual(found.skills.map((s) => s.id).sort(), ["caveman:cavecrew", "caveman:caveman", "single:only", "user:code-review", "user:humanizer"]);
		assert.deepEqual(found.excluded.map((s) => s.id).sort(), ["context-mode:ctx-stats", "synced:docx"]);
		assert.ok(found.diagnostics.some((d) => d.path.endsWith("no-description/SKILL.md")));
		assert.ok(!found.skills.some((s) => s.filePath.includes("/plugins/") || s.filePath.includes("/configs/")));
	});

	it("lets a project skill win a name clash", () => {
		const root = tree(claudeTree);
		const scan = scanSkillsDir(path.join(root, "claude/skills"));
		const found = discoverSkills({ projectSkillsDir: path.join(root, "repo/.claude/skills"), userPlainDirs: scan.plainDirs, plugins: scan.plugins }, [], parseFixture);
		const humanizer = found.skills.filter((s) => s.name === "humanizer");
		assert.equal(humanizer.length, 1);
		assert.equal(humanizer[0].source, "project");
	});

	it("caps descriptions, then shrinks them evenly to fit the budget, without mutating input", () => {
		const long = "word ".repeat(400);
		const skills = [
			{ name: "a", description: long, filePath: "/s/a/SKILL.md" },
			{ name: "b", description: "short\n  text", filePath: "/s/b/SKILL.md" },
			{ name: "c", description: long, filePath: "/s/c/SKILL.md", disableModelInvocation: true },
		];
		const capped = applyListingBudget(skills, 100_000, 500);
		assert.equal(capped[0].description.length, 500);
		assert.equal(capped[1].description, "short text");
		assert.equal(skills[0].description, long);

		const tight = applyListingBudget(skills, 400, 500);
		assert.ok(tight[0].description.length < 500 && tight[0].description.endsWith("…"));
		assert.equal(tight[2].description.length, 500);
	});

	it("builds the same message as pi's /skill:name expansion", () => {
		assert.equal(
			skillInvocation("x", "/s/x/SKILL.md", "\nDo it.\n", " now "),
			'<skill name="x" location="/s/x/SKILL.md">\nReferences are relative to /s/x.\n\nDo it.\n</skill>\n\nnow',
		);
	});
});

describe("agents", () => {
	it("discovers user, plugin (namespaced) and built-in agents; project wins by name", () => {
		const root = tree(claudeTree);
		const scan = scanSkillsDir(path.join(root, "claude/skills"));
		const found = discoverAgents(
			{ projectAgentsDir: path.join(root, "repo/.claude/agents"), userAgentsDir: path.join(root, "claude/agents"), plugins: scan.plugins, builtins: true },
			["Plan"],
			parseFixture,
		);
		const names = found.agents.map((a) => a.name);
		assert.deepEqual(names, ["planner", "caveman:cavecrew-builder", "general-purpose", "Explore"]);
		assert.equal(found.agents[0].source, "project");
		assert.equal(found.agents[0].model, "sonnet");
	});

	it("maps Claude tool names to pi tools", () => {
		assert.deepEqual(mapTools(["Read", "Grep", "Glob"], []), { tools: ["read", "grep", "find"], dropped: [] });
		assert.deepEqual(mapTools([], []), { tools: undefined, dropped: [] });
		assert.deepEqual(mapTools(["*"], ["Bash"]), { tools: ["read", "edit", "write"], dropped: [] });
		assert.deepEqual(mapTools(["Read", "Edit", "MultiEdit", "WebFetch"], []), { tools: ["read", "edit"], dropped: ["WebFetch"] });
		assert.deepEqual(mapTools(["WebSearch"], []), { tools: [], dropped: ["WebSearch"] });
	});

	it("inherits the parent model unless the tier is mapped", () => {
		assert.equal(resolveModel("opus", {}, "openai/gpt-5.5"), "openai/gpt-5.5");
		assert.equal(resolveModel("opus", { opus: "anthropic/claude-opus-5-5" }, "openai/gpt-5.5"), "anthropic/claude-opus-5-5");
		assert.equal(resolveModel(undefined, { opus: "x" }, undefined), undefined);
	});

	it("lists agents with trimmed descriptions and their tools", () => {
		const catalog = formatAgentCatalog(BUILTIN_AGENTS, 30);
		assert.match(catalog, /^- general-purpose: .{1,30} \(Tools: all default tools\)$/m);
		assert.match(catalog, /^- Explore: .+ \(Tools: read, grep, find, ls, bash\)$/m);
	});
});

describe("discover", () => {
	it("ignores the project .claude until the project is trusted", () => {
		const root = tree(claudeTree);
		const config = { ...DEFAULT_CONFIG, claudeDir: path.join(root, "claude") };
		const untrusted = discover(config, path.join(root, "repo"), false, parseFixture);
		assert.equal(untrusted.projectClaudeDir, undefined);
		assert.equal(untrusted.rules.scoped.length, 0);
		assert.equal(untrusted.agents.agents.find((a) => a.name === "planner")?.source, "user");

		const trusted = discover(config, path.join(root, "repo"), true, parseFixture);
		assert.equal(trusted.projectClaudeDir, path.join(root, "repo/.claude"));
		assert.deepEqual(trusted.rules.scoped.map((r) => r.id), ["project:p.md"]);
		assert.deepEqual(trusted.rules.always.map((r) => r.id), ["user:common/a.md"]);
		assert.equal(trusted.agents.agents.find((a) => a.name === "planner")?.source, "project");
	});
});
