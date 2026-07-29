---
name: pull-skill
description: Load an on-demand skill from the Kariimc/my-skills library into this session. The session-start sync only auto-loads the always-load.txt core; use this to pull any of the other library skills when a task needs one. Triggers on "pull skill", "load the <name> skill", "get me the <name> skill", or any task where a library skill exists but is not currently loaded.
---

# Pull-Skill

Bring one library skill (or all of them) into the current session.

`$ARGUMENTS` is the skill name, or `--all` for the whole library.

## Step 1 — find the library

Try these in order and use the first that works:

1. **Local clone.** Read the SessionStart hook command in `~/.claude/settings.json`
   — it is `bash "<repo>/.claude/hooks/session-start.sh" "<repo>"`. Use that `<repo>`.
2. **Current repo.** If `./skills/` exists and contains `session-reflect/`, that is
   the library.
3. **Remote.** The library is public at `Kariimc/my-skills`. Fetch
   `https://raw.githubusercontent.com/Kariimc/my-skills/main/skills/<name>/SKILL.md`
   (GitHub raw is reachable even when general egress is blocked). The index of
   names is the directory listing in the repo, or `always-load.txt` for the core.

## Step 2 — resolve the name

If no skill matches `$ARGUMENTS` exactly, run the finder and offer the closest
matches, then stop:

```
python3 skills/finding-skills/tool/find-skills.py "$ARGUMENTS"
```

Never guess a substitute skill — name the misses and let the user pick.

## Step 3 — load it

- **Local library:** copy `<repo>/skills/<name>` → `~/.claude/skills/<name>`
  (`--all` copies every directory).
- **Remote only:** read the fetched `SKILL.md` into context and follow it directly
  for this session, and say plainly that it is loaded for this session only.

## Step 4 — confirm, and make it stick

Say which skill loaded and from where. Skills are discovered at session start, so
if it is not immediately usable, one restart picks it up. To make it permanent,
add the name to `<repo>/always-load.txt` — offer to do that in the same turn.

## Read it in full

Once pulled, read the whole `SKILL.md` before acting on it. Skimming a pulled
skill and running a partial version of its method is the top quality failure —
a named skill means its full method, every phase, no substitutions.
