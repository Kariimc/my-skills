---
description: Manually sync this repo's skills/, rules/, and commands/ into ~/.claude/ so changes go live without restarting the session.
---

Run the global sync now instead of waiting for the next SessionStart.

Execute the repo's sync hook against the current checkout:

```bash
CLAUDE_PROJECT_DIR="$CLAUDE_PROJECT_DIR" bash "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh" >/dev/null
```

Then confirm what landed:

```bash
echo "skills:";   ls "$HOME/.claude/skills" | wc -l
echo "commands:"; ls "$HOME/.claude/commands" 2>/dev/null
echo "CLAUDE.md:"; wc -l "$HOME/.claude/CLAUDE.md"
```

Report the counts back to me. Note: newly synced skills/commands are picked up
by Claude Code on the next session start.
