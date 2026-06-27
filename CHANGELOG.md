# Changelog

## 2026-06-27

### Global operating rules replaced (`~/.claude/CLAUDE.md`)
Rewrote the global Claude instructions from scratch. New rules cover: SEEN vs STORED (no stating guesses as fact), voice/tone, output discipline (answer first, no narration), DON'T MAKE ME DO LEGWORK (highest priority), role, effort router (Trivial/Standard/Major), lifecycle, prototype gate, quality bars, honest partner mode, failure modes, version control, and a DONE definition.

### codebase-memory-mcp added as MCP server
- Added `bin/install-codebase-memory.sh` — a one-time setup script that installs the [codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp) server and wires it into both Claude Code and Claude Desktop.
- codebase-memory-mcp builds a knowledge graph of your codebase (function calls, dependencies, dead code) so Claude can answer code questions without re-reading every file. Runs fully locally, no API key needed.
- Merged via PR #12.
- Manually installed and verified working in Claude Desktop on Windows (toggled on and connected).
