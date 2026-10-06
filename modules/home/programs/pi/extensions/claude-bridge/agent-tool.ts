/**
 * The `Agent` tool: Claude Code's subagent tool, on pi.
 *
 * Same schema as Claude Code (`description`, `prompt`, `subagent_type`). Each
 * call runs a separate `pi --mode json -p --no-session` process with a fresh
 * context; only the child's final message comes back. Several calls in one
 * assistant message run in parallel, because pi executes them concurrently.
 *
 * Process handling is adapted from pi's examples/extensions/subagent.
 */

import { spawn } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { Message, Usage } from "@earendil-works/pi-ai";
import { type ExtensionAPI, getMarkdownTheme, withFileMutationQueue } from "@earendil-works/pi-coding-agent";
import { Container, Markdown, Spacer, Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import { type AgentDefinition, formatAgentCatalog, mapTools, resolveModel } from "./agents.ts";
import type { BridgeConfig } from "./config.ts";

export const DEPTH_ENV = "PI_CLAUDE_BRIDGE_DEPTH";

export function currentDepth(): number {
	const depth = Number.parseInt(process.env[DEPTH_ENV] ?? "0", 10);
	return Number.isInteger(depth) && depth >= 0 ? depth : 0;
}

interface AgentRun {
	agent: string;
	description: string;
	model: string | undefined;
	exitCode: number;
	messages: Message[];
	stderr: string;
	/** Summed over the child's turns, in pi's shape so session totals include it. */
	usage: Usage;
	turns: number;
	stopReason?: string;
	errorMessage?: string;
	droppedTools: string[];
}

const AgentParams = Type.Object({
	description: Type.String({ description: "A short (3-5 word) description of the task" }),
	prompt: Type.String({ description: "The task for the agent to perform" }),
	subagent_type: Type.String({ description: "The type of specialized agent to use for this task" }),
});

export function registerAgentTool(pi: ExtensionAPI, agents: readonly AgentDefinition[], config: BridgeConfig["agents"]): void {
	pi.registerTool({
		name: "Agent",
		label: "Agent",
		description: [
			"Launch a new agent to handle complex, multi-step tasks autonomously. Each agent runs in its own pi process with a fresh context window, and only its final report comes back to you.",
			"",
			"Available agent types and the tools they have access to:",
			formatAgentCatalog(agents, config.descriptionMaxChars),
			"",
			"Specify the agent with subagent_type. To run several agents in parallel, call this tool several times in one message.",
			"The agent cannot see this conversation: write a self-contained prompt with every path and fact it needs, and say exactly what it should report back.",
		].join("\n"),
		parameters: AgentParams,

		async execute(_toolCallId, params, signal, onUpdate, ctx) {
			const agent = agents.find((candidate) => candidate.name === params.subagent_type);
			if (!agent) {
				throw new Error(`Unknown subagent_type "${params.subagent_type}". Available: ${agents.map((a) => a.name).join(", ")}`);
			}
			const parentModel = ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : undefined;
			const run = await runAgent({
				agent,
				description: params.description,
				prompt: params.prompt,
				cwd: ctx.cwd,
				model: resolveModel(agent.model, config.modelMap, parentModel),
				thinkingLevel: ctx.thinkingLevel ?? pi.getThinkingLevel(),
				signal,
				onProgress: (partial) => onUpdate?.({ content: [{ type: "text", text: finalText(partial) || "(running...)" }], details: partial }),
			});
			if (isFailed(run)) {
				throw new Error(`Agent ${agent.name} failed: ${run.errorMessage || run.stderr.trim() || finalText(run) || `exit code ${run.exitCode}`}`);
			}
			return {
				content: [{ type: "text", text: capBytes(finalText(run) || "(no output)", config.outputMaxBytes) }],
				details: run,
				usage: run.usage,
			};
		},

		renderCall(args, theme) {
			const head = theme.fg("toolTitle", theme.bold("Agent ")) + theme.fg("accent", args.subagent_type ?? "...");
			return new Text(args.description ? `${head}${theme.fg("muted", ` · ${args.description}`)}` : head, 0, 0);
		},

		renderResult(result, { expanded }, theme) {
			const run = result.details as AgentRun | undefined;
			if (!run) {
				const first = result.content[0];
				return new Text(first?.type === "text" ? first.text : "", 0, 0);
			}
			const icon = isFailed(run) ? theme.fg("error", "✗") : theme.fg("success", "✓");
			const status = `${icon} ${theme.fg("toolTitle", run.agent)} ${theme.fg("dim", formatUsage(run))}`;
			if (!expanded) {
				const calls = toolCalls(run).slice(-5).map((call) => theme.fg("muted", `  → ${call}`));
				return new Text([status, ...calls].join("\n"), 0, 0);
			}
			const container = new Container();
			container.addChild(new Text(status, 0, 0));
			for (const call of toolCalls(run)) container.addChild(new Text(theme.fg("muted", `  → ${call}`), 0, 0));
			container.addChild(new Spacer(1));
			container.addChild(new Markdown(finalText(run) || "(no output)", 0, 0, getMarkdownTheme()));
			return container;
		},
	});
}

interface RunOptions {
	agent: AgentDefinition;
	description: string;
	prompt: string;
	cwd: string;
	model: string | undefined;
	thinkingLevel: string | undefined;
	signal: AbortSignal | undefined;
	onProgress: (partial: AgentRun) => void;
}

async function runAgent(options: RunOptions): Promise<AgentRun> {
	const { agent } = options;
	const mapping = mapTools(agent.tools, agent.disallowedTools);
	const args = ["--mode", "json", "-p", "--no-session"];
	if (options.model) args.push("--model", options.model);
	if (options.thinkingLevel) args.push("--thinking", options.thinkingLevel);
	if (mapping.tools && mapping.tools.length > 0) args.push("--tools", mapping.tools.join(","));
	if (mapping.tools && mapping.tools.length === 0) args.push("--no-tools");

	const run: AgentRun = {
		agent: agent.name,
		description: options.description,
		model: options.model,
		exitCode: 0,
		messages: [],
		stderr: "",
		usage: emptyUsage(),
		turns: 0,
		droppedTools: mapping.dropped,
	};

	const promptFile = await writeTempPrompt(agent.name, childSystemPrompt(agent));
	try {
		args.push("--append-system-prompt", promptFile.filePath, options.prompt);
		const { exitCode, aborted } = await spawnPi(args, options, run);
		if (aborted) throw new Error(`Agent ${agent.name} was aborted`);
		return { ...run, exitCode };
	} finally {
		fs.rmSync(promptFile.dir, { recursive: true, force: true });
	}
}

function childSystemPrompt(agent: AgentDefinition): string {
	return [
		`You are the "${agent.name}" subagent, started by another agent to do one task. Your final message is returned to it as your report, so make it complete and self-contained. You cannot ask follow-up questions.`,
		agent.systemPrompt,
	]
		.filter((part) => part.trim() !== "")
		.join("\n\n");
}

function spawnPi(args: string[], options: RunOptions, run: AgentRun): Promise<{ exitCode: number; aborted: boolean }> {
	return new Promise((resolve) => {
		const invocation = piInvocation(args);
		const proc = spawn(invocation.command, invocation.args, {
			cwd: options.cwd,
			env: { ...process.env, [DEPTH_ENV]: String(currentDepth() + 1) },
			shell: false,
			stdio: ["ignore", "pipe", "pipe"],
		});
		let buffer = "";
		let aborted = false;

		const onLine = (line: string) => {
			const event = parseEvent(line);
			if (!event) return;
			if (event.type === "message_end" && event.message) {
				recordMessage(run, event.message as Message);
				options.onProgress(run);
			} else if (event.type === "tool_result_end" && event.message) {
				run.messages.push(event.message as Message);
				options.onProgress(run);
			}
		};

		proc.stdout.on("data", (chunk) => {
			buffer += chunk.toString();
			const lines = buffer.split("\n");
			buffer = lines.pop() ?? "";
			for (const line of lines) onLine(line);
		});
		proc.stderr.on("data", (chunk) => {
			run.stderr += chunk.toString();
		});
		proc.on("close", (code) => {
			if (buffer.trim()) onLine(buffer);
			resolve({ exitCode: code ?? 0, aborted });
		});
		proc.on("error", (error) => {
			run.stderr += error.message;
			resolve({ exitCode: 1, aborted });
		});

		const kill = () => {
			aborted = true;
			proc.kill("SIGTERM");
			setTimeout(() => {
				if (proc.exitCode === null) proc.kill("SIGKILL");
			}, 5000).unref();
		};
		if (options.signal?.aborted) kill();
		else options.signal?.addEventListener("abort", kill, { once: true });
	});
}

function parseEvent(line: string): { type?: string; message?: unknown } | undefined {
	if (!line.trim()) return undefined;
	try {
		return JSON.parse(line);
	} catch {
		return undefined;
	}
}

function recordMessage(run: AgentRun, message: Message): void {
	run.messages.push(message);
	if (message.role !== "assistant") return;
	run.turns++;
	if (message.usage) run.usage = addUsage(run.usage, message.usage);
	if (!run.model && message.model) run.model = message.model;
	if (message.stopReason) run.stopReason = message.stopReason;
	if (message.errorMessage) run.errorMessage = message.errorMessage;
}

/** Re-run the pi that is running us: node + cli.js under nix, or the pi binary. */
function piInvocation(args: string[]): { command: string; args: string[] } {
	const script = process.argv[1];
	if (script && !script.startsWith("/$bunfs/root/") && fs.existsSync(script)) {
		return { command: process.execPath, args: [script, ...args] };
	}
	const runtime = path.basename(process.execPath).toLowerCase();
	return /^(node|bun)(\.exe)?$/.test(runtime) ? { command: "pi", args } : { command: process.execPath, args };
}

async function writeTempPrompt(agentName: string, prompt: string): Promise<{ dir: string; filePath: string }> {
	const dir = await fs.promises.mkdtemp(path.join(os.tmpdir(), "pi-claude-agent-"));
	const filePath = path.join(dir, `${agentName.replace(/[^\w.-]+/g, "_")}.md`);
	await withFileMutationQueue(filePath, () => fs.promises.writeFile(filePath, prompt, { encoding: "utf-8", mode: 0o600 }));
	return { dir, filePath };
}

function emptyUsage(): Usage {
	return { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, totalTokens: 0, cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 } };
}

function addUsage(total: Usage, next: Usage): Usage {
	return {
		input: total.input + (next.input || 0),
		output: total.output + (next.output || 0),
		cacheRead: total.cacheRead + (next.cacheRead || 0),
		cacheWrite: total.cacheWrite + (next.cacheWrite || 0),
		totalTokens: total.totalTokens + (next.totalTokens || 0),
		cost: {
			input: total.cost.input + (next.cost?.input || 0),
			output: total.cost.output + (next.cost?.output || 0),
			cacheRead: total.cost.cacheRead + (next.cost?.cacheRead || 0),
			cacheWrite: total.cost.cacheWrite + (next.cost?.cacheWrite || 0),
			total: total.cost.total + (next.cost?.total || 0),
		},
	};
}

function isFailed(run: AgentRun): boolean {
	return run.exitCode !== 0 || run.stopReason === "error" || run.stopReason === "aborted";
}

function finalText(run: AgentRun): string {
	for (let i = run.messages.length - 1; i >= 0; i--) {
		const message = run.messages[i];
		if (message.role !== "assistant") continue;
		const text = message.content
			.filter((part): part is { type: "text"; text: string } => part.type === "text")
			.map((part) => part.text)
			.join("\n")
			.trim();
		if (text) return text;
	}
	return "";
}

function toolCalls(run: AgentRun): string[] {
	return run.messages.flatMap((message) =>
		message.role === "assistant"
			? message.content.filter((part) => part.type === "toolCall").map((part) => `${part.name} ${preview(part.arguments)}`)
			: [],
	);
}

function preview(args: unknown): string {
	const text = JSON.stringify(args) ?? "";
	return text.length > 70 ? `${text.slice(0, 70)}…` : text;
}

function formatUsage(run: AgentRun): string {
	const { usage } = run;
	const parts = [`${run.turns} turn${run.turns === 1 ? "" : "s"}`, `↑${usage.input}`, `↓${usage.output}`];
	if (usage.cost.total) parts.push(`$${usage.cost.total.toFixed(4)}`);
	if (run.model) parts.push(run.model);
	if (run.droppedTools.length > 0) parts.push(`dropped: ${run.droppedTools.join(",")}`);
	return parts.join(" ");
}

function capBytes(text: string, maxBytes: number): string {
	const size = Buffer.byteLength(text, "utf8");
	if (size <= maxBytes) return text;
	let cut = text.slice(0, maxBytes);
	while (Buffer.byteLength(cut, "utf8") > maxBytes) cut = cut.slice(0, -1);
	return `${cut}\n\n[Report truncated: ${size - Buffer.byteLength(cut, "utf8")} bytes omitted. The full report is in the tool result details.]`;
}
