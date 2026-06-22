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
# All rules/*.md are concatenated (sorted by filename) into one global CLAUDE.md.
if [ -d "$PROJECT_DIR/rules" ] && compgen -G "$PROJECT_DIR/rules/*.md" > /dev/null; then
  : > "$CLAUDE_DIR/CLAUDE.md"
  for rule in "$PROJECT_DIR"/rules/*.md; do
    cat "$rule" >> "$CLAUDE_DIR/CLAUDE.md"
    printf '\n\n' >> "$CLAUDE_DIR/CLAUDE.md"
  done
fi

# ── 3. Slash commands ────────────────────────────────────────────────────────
if [ -d "$PROJECT_DIR/commands" ] && compgen -G "$PROJECT_DIR/commands/*.md" > /dev/null; then
  mkdir -p "$CLAUDE_DIR/commands"
  cp -r "$PROJECT_DIR/commands/." "$CLAUDE_DIR/commands/"
fi

# ── 4. Launcher settings (preserved from previous setup) ─────────────────────
if [ -f "$PROJECT_DIR/.claude/launcher-settings.json" ]; then
  cp "$PROJECT_DIR/.claude/launcher-settings.json" "$CLAUDE_DIR/launcher-settings.json"
fi
