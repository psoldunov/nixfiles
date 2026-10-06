import assert from "node:assert/strict";
import * as os from "node:os";
import * as path from "node:path";
import { after, describe, it } from "node:test";
import { DEFAULT_CONFIG, expandHome, loadConfig, loadSkillListingSettings, parseConfig } from "../config.ts";
import { toStringList } from "../frontmatter.ts";
import { findProjectClaudeDir, matchesAnyGlob, projectAncestors, wildcardMatch } from "../paths.ts";
import { makeTree, removeTree } from "./helpers.ts";

const trees: string[] = [];
const tree = (files: Record<string, string>) => {
	const root = makeTree(files);
	trees.push(root);
	return root;
};
after(() => trees.forEach(removeTree));

describe("toStringList", () => {
	it("accepts comma strings, arrays, and junk", () => {
		assert.deepEqual(toStringList("Read, Grep ,Glob"), ["Read", "Grep", "Glob"]);
		assert.deepEqual(toStringList(["Read", " Bash ", 3, ""]), ["Read", "Bash"]);
		assert.deepEqual(toStringList(undefined), []);
		assert.deepEqual(toStringList({ a: 1 }), []);
	});
});

describe("parseConfig", () => {
	it("returns defaults for an empty object", () => {
		const { value, diagnostics } = parseConfig({}, "cfg.json");
		assert.deepEqual(value, DEFAULT_CONFIG);
		assert.deepEqual(diagnostics, []);
	});

	it("merges valid fields and reports invalid ones", () => {
		const { value, diagnostics } = parseConfig(
			{ skills: { exclude: ["x:*"], aliases: "yes" }, agents: { modelMap: { opus: "anthropic/claude-opus-5-5" }, maxDepth: -1 } },
			"cfg.json",
		);
		assert.deepEqual(value.skills.exclude, ["x:*"]);
		assert.equal(value.skills.aliases, DEFAULT_CONFIG.skills.aliases);
		assert.deepEqual(value.agents.modelMap, { opus: "anthropic/claude-opus-5-5" });
		assert.equal(value.agents.maxDepth, DEFAULT_CONFIG.agents.maxDepth);
		assert.deepEqual(
			diagnostics.map((d) => d.message),
			['invalid "skills.aliases", using default', 'invalid "agents.maxDepth", using default'],
		);
	});

	it("expands ~ in claudeDir", () => {
		assert.equal(parseConfig({ claudeDir: "~/.claude" }, "c").value.claudeDir, path.join(os.homedir(), ".claude"));
		assert.equal(expandHome("/abs"), "/abs");
	});

	it("treats a missing file as defaults and a broken file as a diagnostic", () => {
		const root = tree({ "bad.json": "{nope" });
		assert.deepEqual(loadConfig(path.join(root, "missing.json")), { value: DEFAULT_CONFIG, diagnostics: [] });
		const broken = loadConfig(path.join(root, "bad.json"));
		assert.equal(broken.value, DEFAULT_CONFIG);
		assert.equal(broken.diagnostics.length, 1);
	});

	it("reads Claude Code's skill listing budget", () => {
		const root = tree({ "settings.json": JSON.stringify({ skillListingBudgetFraction: 0.02, skillListingMaxDescChars: 2048 }) });
		assert.deepEqual(loadSkillListingSettings(path.join(root, "settings.json")).value, { budgetFraction: 0.02, maxDescChars: 2048 });
	});
});

describe("paths", () => {
	it("matches globs relative to the root, and absolute paths outside it", () => {
		const root = "/work/repo";
		assert.equal(matchesAnyGlob("src/app.ts", ["**/*.ts"], root), true);
		assert.equal(matchesAnyGlob("/work/repo/src/app.tsx", ["**/*.ts"], root), false);
		assert.equal(matchesAnyGlob("/elsewhere/lib/x.ts", ["**/*.ts"], root), true);
		assert.equal(matchesAnyGlob("style.css", ["**/*.css"], root), true);
		assert.equal(matchesAnyGlob("src/a.ts", ["lib/**"], root), false);
	});

	it("wildcards match ids literally except *", () => {
		assert.equal(wildcardMatch("context-mode:ctx-stats", "context-mode:*"), true);
		assert.equal(wildcardMatch("caveman:caveman", "context-mode:*"), false);
		assert.equal(wildcardMatch("a.b", "a.b"), true);
		assert.equal(wildcardMatch("axb", "a.b"), false);
	});

	it("walks up to the git root and finds the project .claude, never the user one", () => {
		const root = tree({ "repo/.git/HEAD": "", "repo/.claude/rules/x.md": "x", "repo/src/deep/file.ts": "", "home/.claude/CLAUDE.md": "" });
		const cwd = path.join(root, "repo/src/deep");
		assert.deepEqual(projectAncestors(cwd), [cwd, path.join(root, "repo/src"), path.join(root, "repo")]);
		assert.equal(findProjectClaudeDir(cwd, path.join(root, "home/.claude")), path.join(root, "repo/.claude"));
		assert.equal(findProjectClaudeDir(path.join(root, "repo"), path.join(root, "repo/.claude")), undefined);
	});

	it("outside a repository only the working directory counts", () => {
		const root = tree({ "a/.claude/x": "", "a/b/file": "" });
		assert.deepEqual(projectAncestors(path.join(root, "a/b")), [path.join(root, "a/b")]);
	});
});
