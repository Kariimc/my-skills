#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# install-codebase-memory.sh — set up the codebase-memory-mcp server for BOTH
# Claude Code and the Claude Desktop app. Run it ONCE per computer (macOS/Linux;
# Windows users see the note at the bottom of this file).
#
# What is this?
#   codebase-memory-mcp (https://github.com/DeusData/codebase-memory-mcp) is an
#   MCP server — a small helper program Claude can talk to. It reads your code
#   and builds a "map" (a knowledge graph) so Claude can answer questions about
#   function calls, dependencies, and dead code without re-scanning every file.
#   It is a single binary, runs fully locally, and needs no API keys.
#
# What this script does (idempotent — safe to re-run):
#   1. Downloads the binary to ~/.local/bin/codebase-memory-mcp via the official
#      installer. That installer also auto-wires Claude Code for you.
#   2. Adds the server to the Claude DESKTOP app's config, which the official
#      installer does NOT touch. Existing servers in that file are preserved.
# ─────────────────────────────────────────────────────────────────────────────

SERVER_NAME="codebase-memory-mcp"
BIN="$HOME/.local/bin/codebase-memory-mcp"

echo "==> 1/2  Installing the codebase-memory-mcp binary (and wiring Claude Code)"
curl -fsSL https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.sh | bash

if [ ! -x "$BIN" ]; then
  echo "ERROR: expected the binary at $BIN but it is not there." >&2
  echo "The download step above may have failed — re-read its output." >&2
  exit 1
fi

# ── Locate the Claude Desktop config for this OS ─────────────────────────────
case "$(uname -s)" in
  Darwin)  CFG_DIR="$HOME/Library/Application Support/Claude" ;;   # macOS
  Linux)   CFG_DIR="$HOME/.config/Claude" ;;                       # Linux
  MINGW*|MSYS*|CYGWIN*) CFG_DIR="${APPDATA:-$HOME/AppData/Roaming}/Claude" ;; # Git Bash
  *)       CFG_DIR="$HOME/.config/Claude" ;;
esac
CFG="$CFG_DIR/claude_desktop_config.json"

echo "==> 2/2  Adding $SERVER_NAME to Claude Desktop  ($CFG)"
mkdir -p "$CFG_DIR"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not found — cannot safely merge JSON. Add this block to $CFG by hand:" >&2
  cat >&2 <<EOF
{
  "mcpServers": {
    "$SERVER_NAME": { "command": "$BIN", "args": [] }
  }
}
EOF
  exit 1
fi

CFG="$CFG" SERVER_NAME="$SERVER_NAME" BIN="$BIN" python3 - <<'PY'
import json, os

cfg  = os.environ["CFG"]
name = os.environ["SERVER_NAME"]
binp = os.environ["BIN"]

try:
    with open(cfg) as f:
        data = json.load(f)
    if not isinstance(data, dict):
        data = {}
except (FileNotFoundError, ValueError):
    data = {}

servers = data.setdefault("mcpServers", {})
servers[name] = {"command": binp, "args": []}   # add or update, leave others alone

tmp = cfg + ".tmp"
with open(tmp, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
os.replace(tmp, cfg)
print(f"[ok] {name} registered in Claude Desktop config")
PY

echo
echo "Done."
echo "  • Claude Code   : configured by the official installer (restart not usually needed)."
echo "  • Claude Desktop: QUIT and reopen the app so it loads the new server."
echo
echo "How to know it worked: in Claude Desktop, open Settings → Developer (or the"
echo "tools/plug icon in a chat) and confirm '$SERVER_NAME' is listed as connected."

# ─────────────────────────────────────────────────────────────────────────────
# WINDOWS (PowerShell, not Git Bash):
#   1. Install the binary:
#        Invoke-WebRequest -Uri https://raw.githubusercontent.com/DeusData/codebase-memory-mcp/main/install.ps1 -OutFile install.ps1; .\install.ps1
#   2. Edit  %APPDATA%\Claude\claude_desktop_config.json  and add, under
#      "mcpServers", a "codebase-memory-mcp" entry whose "command" is the full
#      path to the installed codebase-memory-mcp.exe (the installer prints it).
#   3. Quit and reopen Claude Desktop.
# ─────────────────────────────────────────────────────────────────────────────
