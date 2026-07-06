Review this sync design and name the single most important issue, its blast
radius, and the fix: a SessionStart hook syncs a repo to ~/.claude/ with
`cp -r repo/skills/. ~/.claude/skills/` (same pattern for commands and agents);
rules are different — they are rebuilt from zero into CLAUDE.md each sync.
