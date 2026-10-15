"""Exercise the real MCP stdio protocol without controller credentials or traffic."""

import importlib.util
import sys
import unittest
from pathlib import Path

MODULE = Path(__file__).parents[1] / "unifi_readonly.py"


@unittest.skipUnless(importlib.util.find_spec("mcp"), "MCP SDK not installed in this Python environment")
class MCPStdioTests(unittest.IsolatedAsyncioTestCase):
    async def test_handshake_tools_and_rejected_input(self):
        from mcp import ClientSession, StdioServerParameters
        from mcp.client.stdio import stdio_client

        parameters = StdioServerParameters(
            command=sys.executable,
            args=[str(MODULE), "mcp"],
            env={"UNIFI_API_KEY_FILE": "/nonexistent-unifi-test-key"},
        )
        async with stdio_client(parameters) as (reader, writer):
            async with ClientSession(reader, writer) as session:
                await session.initialize()
                tools = await session.list_tools()
                self.assertEqual(len(tools.tools), 8)
                result = await session.call_tool("list_devices", {"site_id": "../../unsafe"})
                self.assertTrue(result.isError)
                self.assertIn("site_id must be a UUID", str(result.content))
                result = await session.call_tool("info", {})
                self.assertTrue(result.isError)
                self.assertIn("API key file is unavailable", str(result.content))


if __name__ == "__main__":
    unittest.main()
