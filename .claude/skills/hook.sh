#!/bin/bash
set -euo pipefail

# Run async so skills are installed in background while session starts
echo '{"async": true, "asyncTimeout": 60000}'

# Only run in remote Claude Code environments
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

SKILLS_SRC="${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude/skills"
SKILLS_DEST="$HOME/.claude/skills"

if [ ! -d "$SKILLS_SRC" ]; then
  exit 0
fi

mkdir -p "$SKILLS_DEST"
cp -r "$SKILLS_SRC/." "$SKILLS_DEST/"
