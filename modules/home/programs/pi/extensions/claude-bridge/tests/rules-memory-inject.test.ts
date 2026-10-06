import assert from "node:assert/strict";
import * as fs from "node:fs";
import * as path from "node:path";
import { after, describe, it } from "node:test";
import { collectMarkers, planInjection } from "../inject.ts";
import { alwaysMemoryFiles, nestedMemoryPaths } from "../memory.ts";
import { discoverRules, renderAlwaysSection, TOOL_GLOSSARY } from "../rules.ts";
import { makeTree, md, parseFixture, removeTree } from "./helpers.ts";

const trees: string[] = [];
const tree = (files: Record<string, string>) => {
	const root = makeTree(files);
	trees.push(root);
	return root;
};
after(() => trees.forEach(removeTree));

const ruleFiles = {
	"rules/common/style.md": "# Style\nNo mutation.\n",
	"rules/common/empty.md": "   \n",
	"rules/typescript/testing.md": md('paths:\n  - "**/*.ts"\n  - "**/*.tsx"', "# TS testing\nUse vitest.\n"),
	"rules/web/tailwind.md": md('paths:\n  - "**/*.css"', "# Tailwind\nUse cn().\n"),
};

describe("discoverRules", () => {
	it("splits always-on and path-scoped rules, skipping empty bodies", () => {
		const root = tree(ruleFiles);
		const set = discoverRules([{ source: "user", dir: path.join(root, "rules") }], parseFixture);
		assert.deepEqual(set.always.map((rule) => rule.id), ["user:common/style.md"]);
		assert.deepEqual(set.scoped.map((rule) => rule.id), ["user:typescript/testing.md", "user:web/tailwind.md"]);
		assert.deepEqual(set.scoped[0].paths, ["**/*.ts", "**/*.tsx"]);
	});

	it("follows symlinked rule directories without looping", () => {
		const root = tree({ "rules/common/a.md": "a\n" });
		fs.symlinkSync(path.join(root, "rules"), path.join(root, "rules/common/loop"));
		const set = discoverRules([{ source: "user", dir: path.join(root, "rules") }], parseFixture);
		assert.deepEqual(set.always.map((rule) => rule.id), ["user:common/a.md"]);
	});

	it("renders a stable section with the tool glossary and source paths", () => {
		const root = tree(ruleFiles);
		const set = discoverRules([{ source: "user", dir: path.join(root, "rules") }], parseFixture);
		const section = renderAlwaysSection(set.always);
		assert.ok(section.startsWith(TOOL_GLOSSARY));
		assert.ok(section.includes(`<rule path="${path.join(root, "rules/common/style.md")}">\n# Style\nNo mutation.\n</rule>`));
		assert.equal(renderAlwaysSection(set.always), section);
		assert.equal(renderAlwaysSection([]), "");
	});
});

describe("memory", () => {
	it("loads user, project .claude and CLAUDE.local.md once, outermost first", () => {
		const root = tree({
			"home/.claude/CLAUDE.md": "user memory",
			"repo/.git/HEAD": "",
			"repo/.claude/CLAUDE.md": "project memory",
			"repo/CLAUDE.local.md": "local memory",
			"repo/pkg/CLAUDE.local.md": "pkg local",
		});
		const files = alwaysMemoryFiles({
			claudeDir: path.join(root, "home/.claude"),
			cwd: path.join(root, "repo/pkg"),
			projectClaudeDir: path.join(root, "repo/.claude"),
			existing: [path.join(root, "repo/pkg/CLAUDE.local.md")],
		});
		assert.deepEqual(
			files.map((file) => [path.relative(root, file.path), file.content]),
			[
				["home/.claude/CLAUDE.md", "user memory"],
				["repo/.claude/CLAUDE.md", "project memory"],
				["repo/CLAUDE.local.md", "local memory"],
			],
		);
	});

	it("finds nested CLAUDE.md below cwd only", () => {
		const root = tree({ "CLAUDE.md": "root", "mod/CLAUDE.md": "mod", "mod/sub/CLAUDE.md": "sub", "mod/sub/file.nix": "" });
		assert.deepEqual(nestedMemoryPaths("mod/sub/file.nix", root), [path.join(root, "mod/CLAUDE.md"), path.join(root, "mod/sub/CLAUDE.md")]);
		assert.deepEqual(nestedMemoryPaths("top.nix", root), []);
		assert.deepEqual(nestedMemoryPaths("/etc/hosts", root), []);
	});
});

describe("lazy injection", () => {
	const setup = () => {
		const root = tree({ ...ruleFiles, "app/CLAUDE.md": "app rules", "app/main.ts": "" });
		const rules = discoverRules([{ source: "user", dir: path.join(root, "rules") }], parseFixture);
		return { root, scoped: rules.scoped };
	};

	it("injects matching rules and nested memory once, then honours markers", () => {
		const { root, scoped } = setup();
		const first = planInjection({ filePath: "app/main.ts", cwd: root, projectRoot: root, scopedRules: scoped, nestedMemory: true, skip: new Set() });
		assert.ok(first);
		assert.deepEqual(first.keys, [`memory:${path.join(root, "app/CLAUDE.md")}`, "rule:user:typescript/testing.md"]);
		assert.ok(first.text.startsWith("<system-reminder>\n<claude-memory id="));
		assert.ok(first.text.includes("Use vitest."));
		assert.ok(!first.text.includes("Use cn()."));

		const markers = collectMarkers([{ role: "toolResult", content: [{ type: "text", text: first.text }] }]);
		assert.deepEqual([...markers].sort(), [...first.keys].sort());
		const second = planInjection({ filePath: "app/main.ts", cwd: root, projectRoot: root, scopedRules: scoped, nestedMemory: true, skip: markers });
		assert.equal(second, undefined);
	});

	it("does nothing for files no rule covers", () => {
		const { root, scoped } = setup();
		assert.equal(planInjection({ filePath: "README.md", cwd: root, projectRoot: root, scopedRules: scoped, nestedMemory: true, skip: new Set() }), undefined);
	});

	it("resolves rule globs from the project root when pi runs in a subdirectory", () => {
		const root = tree({ "rules/src.md": md('paths:\n  - "src/**/*.ts"', "src rule\n"), "src/lib/x.ts": "" });
		const scoped = discoverRules([{ source: "user", dir: path.join(root, "rules") }], parseFixture).scoped;
		const cwd = path.join(root, "src");
		const hit = planInjection({ filePath: "lib/x.ts", cwd, projectRoot: root, scopedRules: scoped, nestedMemory: false, skip: new Set() });
		assert.deepEqual(hit?.keys, ["rule:user:src.md"]);
		const miss = planInjection({ filePath: "lib/x.ts", cwd, projectRoot: cwd, scopedRules: scoped, nestedMemory: false, skip: new Set() });
		assert.equal(miss, undefined);
	});

	it("collects markers from string and part-array content, ignoring other parts", () => {
		const markers = collectMarkers([
			{ role: "user", content: 'x <claude-rule id="user:a.md" path="p">' },
			{ role: "assistant", content: [{ type: "toolCall", text: '<claude-rule id="no">' }] },
			null,
			{ role: "toolResult" },
		]);
		assert.deepEqual([...markers], ["rule:user:a.md"]);
	});
});
