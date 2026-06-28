# Important Rules

1. Address the user as "花花虎" in every response.
2. Reply in Chinese. English technical terms such as UIKit and token are fine.
3. When running `curl` or similar Bash network commands, prefix each command with the full local proxy environment so both HTTP and HTTPS traffic use port 1082.
   - No proxy needed when talking to the remote ai server
   - Apply this to commands that fetch, install, or upload over the network, such as `curl`, `wget`, `npm install`, `brew install`, `git fetch`, `git pull`, `git push`, `git clone`, `gh pr`, `gh issue`, `gh repo`, `pip install`, `pod install`, `bundle install`, and `swift package resolve`. 
   - Do not add proxy environment variables for local-only commands, such as `ls`, `pwd`, `rg`, `find`, `git status`, `git diff`, `git log`, local `npm test`, local `xcodebuild` build/test, and local `swift test`.
   - Use this inline pattern before the actual command and target URL/address:
     `HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 <command> <url-or-address>`
   - For example:
     `HTTP_PROXY=http://127.0.0.1:1082 HTTPS_PROXY=http://127.0.0.1:1082 ALL_PROXY=http://127.0.0.1:1082 http_proxy=http://127.0.0.1:1082 https_proxy=http://127.0.0.1:1082 all_proxy=http://127.0.0.1:1082 NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 curl https://www.google.com`
   - If a command does not honor proxy environment variables, use its explicit proxy flag instead, such as `curl --proxy http://127.0.0.1:1082 https://www.google.com`.
   - If the local proxy service explicitly requires an HTTPS proxy endpoint, use `https://127.0.0.1:1082` for `HTTPS_PROXY` and `https_proxy`; otherwise keep `http://127.0.0.1:1082` because HTTP proxy endpoints normally tunnel HTTPS targets with `CONNECT`.

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

The `xcodebuildmcp` command is installed as a CLI. Prefer it over `xcrun simctl`.

Project defaults live in `.xcodebuildmcp/config.yaml`.

At the start of each new agent session, before the first XcodeBuildMCP build, run, or test call, show active defaults with `session_show_defaults`.

If active defaults are missing or differ from `.xcodebuildmcp/config.yaml`, read that file and apply its `sessionDefaults` with `session_set_defaults` before building, running, or testing.

Do not assume the MCP server automatically loads this repository's config file. It only reads `.xcodebuildmcp/config.yaml` from the MCP process current working directory, which may not be the repository root. If configuring the MCP server startup, set `XCODEBUILDMCP_CWD` to the repository root.
