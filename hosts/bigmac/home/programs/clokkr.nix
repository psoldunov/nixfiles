# Clokkr's MCP server for Claude Code, Codex and pi. Clokkr's flake builds for
# Linux only, so the Mac runs the CLI inside the installed Clokkr.app.
{
  programs.mcp.servers.clokkr = {
    command = "/Applications/Clokkr.app/Contents/MacOS/clokkr";
    args = ["mcp"];
  };
}
