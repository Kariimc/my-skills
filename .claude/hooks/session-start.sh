#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Global Claude config sync (SessionStart hook)
#
# This repo is the SOURCE OF TRUTH for your global Claude setup. On every
# session start this hook copies the repo's top-level folders into ~/.claude/,
# which is the directory Claude Code reads for EVERY project. That is what makes
# these skills, rules, and commands available globally — not just in this repo.
#
#   skills/    ->  ~/.claude/skills/    (auto-discovered skills, all projects)
#   rules/     ->  ~/.claude/CLAUDE.md  (global instructions, all projects)
#   commands/  ->  ~/.claude/commands/  (slash commands, all projects)
#   agents/    ->  ~/.claude/agents/    (subagents, all projects)
# ─────────────────────────────────────────────────────────────────────────────

# Run async so the session starts immediately; sync finishes in the background.
echo '{"async": true, "asyncTimeout": 60000}'

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"

# ── 1. Skills ────────────────────────────────────────────────────────────────
if [ -d "$PROJECT_DIR/skills" ]; then
  mkdir -p "$CLAUDE_DIR/skills"
  cp -r "$PROJECT_DIR/skills/." "$CLAUDE_DIR/skills/"
fi

# ── 2. Rules -> global CLAUDE.md ─────────────────────────────────────────────
# All rules/*.md (except README.md) are concatenated, sorted, into CLAUDE.md.
if [ -d "$PROJECT_DIR/rules" ] && compgen -G "$PROJECT_DIR/rules/*.md" > /dev/null; then
  : > "$CLAUDE_DIR/CLAUDE.md"
  for rule in "$PROJECT_DIR"/rules/*.md; do
    [ "$(basename "$rule")" = "README.md" ] && continue
    cat "$rule" >> "$CLAUDE_DIR/CLAUDE.md"
    printf '\n\n' >> "$CLAUDE_DIR/CLAUDE.md"
  done
fi

# ── 3. Slash commands ────────────────────────────────────────────────────────
# Each commands/*.md becomes /<name>; README.md is docs, so skip it.
if [ -d "$PROJECT_DIR/commands" ] && compgen -G "$PROJECT_DIR/commands/*.md" > /dev/null; then
  mkdir -p "$CLAUDE_DIR/commands"
  for cmd in "$PROJECT_DIR"/commands/*.md; do
    [ "$(basename "$cmd")" = "README.md" ] && continue
    cp "$cmd" "$CLAUDE_DIR/commands/"
  done
fi

# ── 4. Subagents ─────────────────────────────────────────────────────────────
# Each agents/*.md becomes a callable subagent; README.md is docs, so skip it.
if [ -d "$PROJECT_DIR/agents" ] && compgen -G "$PROJECT_DIR/agents/*.md" > /dev/null; then
  mkdir -p "$CLAUDE_DIR/agents"
  for agent in "$PROJECT_DIR"/agents/*.md; do
    [ "$(basename "$agent")" = "README.md" ] && continue
    cp "$agent" "$CLAUDE_DIR/agents/"
  done
fi

# ── 5. Hooks (global) ────────────────────────────────────────────────────────
# Top-level hooks/*.sh are synced to ~/.claude/hooks/ so they can be wired into
# global (user-level) settings and run in EVERY project — e.g. the harness
# router that auto-routes prompts to the right ultimate-harness skill.
if [ -d "$PROJECT_DIR/hooks" ] && compgen -G "$PROJECT_DIR/hooks/*.sh" > /dev/null; then
  mkdir -p "$CLAUDE_DIR/hooks"
  for hook in "$PROJECT_DIR"/hooks/*.sh; do
    cp "$hook" "$CLAUDE_DIR/hooks/"
    chmod +x "$CLAUDE_DIR/hooks/$(basename "$hook")"
  done
fi

# ── 6. Register the harness router in global settings (idempotent) ────────────
# Adds a UserPromptSubmit hook pointing at the synced router. Additive merge:
# never removes or overwrites existing hooks, and skips if already registered.
ROUTER_PATH="$CLAUDE_DIR/hooks/harness-router.sh"
if command -v python3 >/dev/null 2>&1 && [ -f "$ROUTER_PATH" ]; then
  SETTINGS_FILE="$CLAUDE_DIR/settings.json" ROUTER_CMD="$ROUTER_PATH" python3 - <<'PY' || true
import json, os

path = os.environ["SETTINGS_FILE"]
cmd  = os.environ["ROUTER_CMD"]

try:
    with open(path) as f:
        settings = json.load(f)
    if not isinstance(settings, dict):
        settings = {}
except (FileNotFoundError, ValueError):
    settings = {}

hooks = settings.setdefault("hooks", {})
ups = hooks.setdefault("UserPromptSubmit", [])

# Already registered? (match on the router filename, path-independent)
already = any(
    "harness-router.sh" in (h.get("command", ""))
    for group in ups if isinstance(group, dict)
    for h in group.get("hooks", []) if isinstance(h, dict)
)

if not already:
    ups.append({"hooks": [{"type": "command", "command": cmd}]})
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")
    os.replace(tmp, path)
    print("[session-start] registered harness-router UserPromptSubmit hook")
PY
fi

# ── 7. Launcher settings (preserved from previous setup) ─────────────────────
if [ -f "$PROJECT_DIR/.claude/launcher-settings.json" ]; then
  cp "$PROJECT_DIR/.claude/launcher-settings.json" "$CLAUDE_DIR/launcher-settings.json"
fi
