# Repository Instructions

This repository stores iOS demo projects referenced by blog posts.

## Xcode MCP

Xcode's built-in MCP bridge is configured for this machine through Codex global MCP settings:

```toml
[mcp_servers.xcode-mcp]
command = "xcrun"
args = ["mcpbridge"]

[mcp_servers.xcode-mcp.env]
MCP_XCODE_PID = "<current Xcode PID>"
```

When working on an iOS demo in this repository, prefer Xcode's built-in MCP tools when they are available in the current Codex session.

If Xcode is restarted, update `MCP_XCODE_PID` to the current Xcode process ID or remove the environment variable to let `mcpbridge` auto-detect a single running Xcode instance.

If the MCP tools are not available in a session, use `xcodebuild` directly as a fallback and keep commands scoped to the specific demo project directory.
