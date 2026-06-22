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

# ── 5. Launcher settings (preserved from previous setup) ─────────────────────
if [ -f "$PROJECT_DIR/.claude/launcher-settings.json" ]; then
  cp "$PROJECT_DIR/.claude/launcher-settings.json" "$CLAUDE_DIR/launcher-settings.json"
fi
