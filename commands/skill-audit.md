---
description: Audit every skill in skills/ for frontmatter health, name/dir mismatches, weak trigger descriptions, and overlap between skills.
---

Audit all skills in `skills/` and report findings. Do NOT edit anything unless I confirm.

Check each `skills/*/SKILL.md` for:
1. **Name/dir match** — frontmatter `name:` must equal the directory name.
2. **Description quality** — has a clear role + a "Use when..." trigger clause;
   flag descriptions that are vague or over ~700 characters.
3. **Frontmatter validity** — `name` and `description` both present, valid YAML.
4. **Overlap** — group skills whose triggers could collide (e.g. networking,
   cannabis, web build/deploy, game art) and note which would win ambiguous matches.

Output a short table: skill | issue | suggested fix. End with a ranked list of
the top merge/cleanup opportunities.
