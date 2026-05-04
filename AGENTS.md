# Repository Instructions

This repository stores iOS demo projects referenced by blog posts.

## XcodeBuildMCP

XcodeBuildMCP is configured for this machine through Codex global MCP settings:

```toml
[mcp_servers.xcodebuildmcp]
command = "npx"
args = ["-y", "xcodebuildmcp@2.3.2"]
```

When working on an iOS demo in this repository, prefer XcodeBuildMCP tools for Xcode project discovery, simulator management, building, testing, and app launching when those tools are available in the current Codex session.

If the MCP tools are not available in a session, use `xcodebuild` directly as a fallback and keep commands scoped to the specific demo project directory.

