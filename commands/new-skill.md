---
description: Scaffold a new skill in this repo (skills/<name>/SKILL.md) with correct frontmatter, then sync it globally.
---

Create a new Claude skill in **this repo** using the `skill-builder` skill.

Target name (kebab-case): $ARGUMENTS

Steps:
1. Invoke the `skill-builder` skill to generate the skill body.
2. Write it to `skills/<name>/SKILL.md` (NOT `.claude/skills/`).
3. Ensure the frontmatter `name:` EXACTLY matches the directory `<name>`.
4. Ensure the `description:` starts with the role/purpose and ends with a sharp
   "Use when the user wants to ..." trigger clause — this is what controls
   automatic invocation.
5. Remind me that it goes live globally on the next session (the SessionStart
   hook syncs `skills/` into `~/.claude/skills/`), or that I can run
   `/sync-skills` to push it now.
