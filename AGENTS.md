# Repository Instructions

This repository stores iOS demo projects referenced by blog posts.

## XcodeBuildMCP

XcodeBuildMCP is configured for this machine through project based MCP settings:

```toml
[mcp_servers.xcodebuildmcp]
command = "xcodebuildmcp"
args = ["mcp"]
```

When working on an iOS demo in this repository, prefer XcodeBuildMCP tools for project discovery, simulator management, builds, tests, app launching, and log capture when those tools are available in the current Codex session.

If the MCP tools are not available in a session, use `xcodebuild` directly as a fallback and keep commands scoped to the specific demo project directory.
