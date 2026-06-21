#!/bin/bash
set -euo pipefail

# Run async so session starts immediately
echo '{"async": true, "asyncTimeout": 60000}'

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
CLAUDE_DIR="$HOME/.claude"

# ── 1. Sync all skills ───────────────────────────────────────────────────────
SKILLS_SRC="$PROJECT_DIR/.claude/skills"
if [ -d "$SKILLS_SRC" ]; then
  mkdir -p "$CLAUDE_DIR/skills"
  cp -r "$SKILLS_SRC/." "$CLAUDE_DIR/skills/"
fi

# ── 2. Restore global CLAUDE.md (IDP system instructions) ───────────────────
if [ -f "$PROJECT_DIR/.claude/CLAUDE.md" ]; then
  cp "$PROJECT_DIR/.claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
fi

# ── 3. Restore global sync-skills hook ──────────────────────────────────────
if [ -f "$PROJECT_DIR/.claude/sync-skills.sh" ]; then
  cp "$PROJECT_DIR/.claude/sync-skills.sh" "$CLAUDE_DIR/sync-skills.sh"
  chmod +x "$CLAUDE_DIR/sync-skills.sh"
fi

# ── 4. Restore global launcher-settings.json ────────────────────────────────
if [ -f "$PROJECT_DIR/.claude/launcher-settings.json" ]; then
  cp "$PROJECT_DIR/.claude/launcher-settings.json" "$CLAUDE_DIR/launcher-settings.json"
fi
