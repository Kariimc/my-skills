#!/bin/bash
set -euo pipefail

# Run async so session starts immediately
echo '{"async": true, "asyncTimeout": 60000}'

SKILLS_DEST="$HOME/.claude/skills"
CLAUDE_MD_DEST="$HOME/.claude/CLAUDE.md"

# Sync skills from project repo if available
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR/.claude/skills" ]; then
  mkdir -p "$SKILLS_DEST"
  cp -r "$CLAUDE_PROJECT_DIR/.claude/skills/." "$SKILLS_DEST/"
fi

# Restore global CLAUDE.md from project repo if available
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -f "$CLAUDE_PROJECT_DIR/.claude/CLAUDE.md" ]; then
  cp "$CLAUDE_PROJECT_DIR/.claude/CLAUDE.md" "$CLAUDE_MD_DEST"
fi
