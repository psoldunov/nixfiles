"""Convert Claude Code agents (markdown with YAML frontmatter) into Codex
custom agents: agent-md-to-toml.py OUT_DIR AGENT.md...

Each agent becomes OUT_DIR/<name>.toml with name, description,
developer_instructions (the markdown body) and, when the agent names a Claude
model tier, the reasoning effort that tier maps to. The model itself is left
to the session. An agent whose Claude tools cannot write files gets a
read-only sandbox. Exits non-zero on a malformed agent or a duplicate name.
"""

import json
import sys
import tomllib
from pathlib import Path

import yaml

EFFORT = {"opus": "high", "sonnet": "medium", "haiku": "low"}
WRITE_TOOLS = {"Write", "Edit", "MultiEdit", "NotebookEdit"}


def can_write(tools: object) -> bool:
    """`tools` is a YAML list or a comma-separated string; absent means all tools."""
    if tools is None:
        return True
    names = tools if isinstance(tools, list) else str(tools).split(",")
    return any(str(tool).strip() in WRITE_TOOLS for tool in names)


def convert(path: Path) -> tuple[str, str]:
    text = path.read_text()
    if not text.startswith("---\n"):
        sys.exit(f"{path}: no frontmatter")
    front, closed, body = text[4:].partition("\n---\n")
    if not closed:
        sys.exit(f"{path}: frontmatter is not closed")
    meta = yaml.safe_load(front) or {}
    name, description = meta.get("name"), meta.get("description")
    if not (isinstance(name, str) and name and isinstance(description, str) and description.strip()):
        sys.exit(f"{path}: frontmatter needs a name and a description")

    fields = {
        "name": name,
        "description": description.strip(),
        "developer_instructions": body.strip() + "\n",
    }
    effort = EFFORT.get(meta.get("model"))
    if effort:
        fields["model_reasoning_effort"] = effort
    if not can_write(meta.get("tools")):
        fields["sandbox_mode"] = "read-only"

    # A JSON string is a TOML basic string; the round trip proves it.
    toml = "".join(f"{key} = {json.dumps(value, ensure_ascii=False)}\n" for key, value in fields.items())
    if tomllib.loads(toml) != fields:
        sys.exit(f"{path}: TOML round trip changed the agent")
    return name, toml


def main() -> None:
    out = Path(sys.argv[1])
    seen = set()
    for arg in sys.argv[2:]:
        name, toml = convert(Path(arg))
        if name in seen:
            sys.exit(f"duplicate agent name: {name}")
        seen.add(name)
        (out / f"{name}.toml").write_text(toml)


if __name__ == "__main__":
    main()
