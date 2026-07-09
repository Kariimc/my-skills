---
description: Load an on-demand skill from the my-skills library into this session. The tiered session-start sync only auto-loads the always-load.txt core; use this to pull any of the other library skills when a task needs one.
---

The user wants to load the skill named `$ARGUMENTS` (or `--all` for the whole
library) that is not in the always-load core.

Do this:
1. Resolve the my-skills repo path: read the SessionStart hook command in
   `~/.claude/settings.json` — it is `bash "<repo>/.claude/hooks/session-start.sh" "<repo>"`.
   Use that `<repo>`.
2. If `$ARGUMENTS` is `--all`, copy every dir from `<repo>/skills/` into
   `~/.claude/skills/`. Otherwise copy `<repo>/skills/$ARGUMENTS` into
   `~/.claude/skills/$ARGUMENTS`.
3. If no skill by that name exists, list the closest matches by name and stop.
4. Confirm it's pulled. Skills are discovered at session start, so if it is not
   usable immediately, one session restart loads it. To make it permanent, add
   the name to `<repo>/always-load.txt`.
