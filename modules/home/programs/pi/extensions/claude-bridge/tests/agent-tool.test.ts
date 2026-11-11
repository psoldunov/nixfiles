/**
 * The `Agent` tool end to end against a stand-in child: `piInvocation` re-runs
 * `process.argv[1]`, so pointing that at a small script makes it the child.
 * pi's runtime packages are not installed beside the source, so they resolve
 * to stubs that cover what agent-tool.ts touches.
 */

import assert from "node:assert/strict";
import { registerHooks } from "node:module";
import { after, describe, it } from "node:test";
import { makeTree, removeTree } from "./helpers.ts";

const stubs: Record<string, string> = {
	"@earendil-works/pi-coding-agent": "export const getMarkdownTheme = () => ({}); export const withFileMutationQueue = (_path, fn) => fn();",
	"@earendil-works/pi-tui": "export class Container {} export class Markdown {} export class Spacer {} export class Text {}",
	typebox: "export const Type = { Object: (shape) => shape, String: (options) => options };",
};
registerHooks({
	resolve(specifier, context, next) {
		const stub = stubs[specifier];
		return stub === undefined ? next(specifier, context) : { url: `data:text/javascript,${encodeURIComponent(stub)}`, shortCircuit: true };
	},
});
const { registerAgentTool } = await import("../agent-tool.ts");

const root = makeTree({
	"killed.mjs": `process.kill(process.pid, "SIGKILL");\n`,
	"slow.mjs": `setTimeout(() => {}, 30_000);\n`,
});
after(() => removeTree(root));

type Execute = (id: string, params: unknown, signal: AbortSignal | undefined, onUpdate: undefined, ctx: unknown) => Promise<unknown>;

function agentTool(): Execute {
	let execute: Execute | undefined;
	const pi = { registerTool: (tool: { execute: Execute }) => (execute = tool.execute), getThinkingLevel: () => undefined };
	const agent = { name: "worker", description: "", source: "test", tools: [], disallowedTools: [], model: undefined, systemPrompt: "", filePath: undefined };
	registerAgentTool(pi as never, [agent], { descriptionMaxChars: 100, modelMap: {}, outputMaxBytes: 10_000 } as never);
	assert.ok(execute);
	return execute;
}

async function callWithChild(script: string, signal?: AbortSignal): Promise<unknown> {
	const saved = process.argv[1];
	process.argv[1] = `${root}/${script}`;
	try {
		const params = { description: "d", prompt: "p", subagent_type: "worker" };
		return await agentTool()("call-1", params, signal, undefined, { cwd: root, model: undefined, thinkingLevel: undefined });
	} finally {
		process.argv[1] = saved;
	}
}

describe("Agent tool child exit", () => {
	it("fails when the child is killed by a signal it was not sent by an abort", async () => {
		await assert.rejects(callWithChild("killed.mjs"), /Agent worker failed: .*SIGKILL/);
	});

	it("still reports an abort as an abort", async () => {
		const controller = new AbortController();
		const call = callWithChild("slow.mjs", controller.signal);
		setTimeout(() => controller.abort(), 200);
		await assert.rejects(call, /Agent worker was aborted/);
	});
});
