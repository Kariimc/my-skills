# Commands

Slash commands. Each `*.md` file here becomes `/<filename>` and is synced into
your **global** `~/.claude/commands/` on every session start — so the command
works in every project, not just this repo.

| Command | What it does |
|---|---|
| `/new-skill <name>` | Scaffold a new skill in `skills/<name>/SKILL.md` with correct frontmatter. |
| `/sync-skills` | Push `skills/`, `rules/`, `commands/` into `~/.claude/` right now (no restart). |
| `/skill-audit` | Report frontmatter/name/overlap issues across all skills (read-only). |

## Anatomy of a command file
```markdown
---
description: One line shown in the slash-command menu.
---
The prompt body Claude runs when you type the command.
Use $ARGUMENTS to capture whatever you type after the command name.
```

Add a file → it's a new global command on the next session (or after `/sync-skills`).
