---
description: Audit every skill in skills/ for frontmatter health, name/dir mismatches, weak trigger descriptions, and overlap between skills.
---

Audit all skills in `skills/` and report findings. Do NOT edit anything unless I confirm.

First run the deterministic engine for structural health, then layer the
judgment checks on top:

```bash
bash bin/skill-doctor.sh        # HARD=0 required; lists trigger-less + over-length descriptions
```

Then check each `skills/*/SKILL.md` for:
1. **Name/dir match** — frontmatter `name:` must equal the directory name. (HARD)
2. **Frontmatter validity** — `name` and `description` both present, valid YAML. (HARD)
3. **Description length** — the `description:` value controls auto-invocation and
   is the ONLY text Claude loads for matching. Claude Code rejects/truncates
   descriptions over **1024 characters**, which silently breaks triggering —
   treat over-1024 as HARD. Flag over ~700 as a readability SOFT (except
   intentionally trigger-tuned ones like `docx`, `xlsx`, `claude-api`).
4. **Trigger quality** — the trigger clause must live in the **description**, not
   only in the body's "When to Activate" section (the body isn't loaded for
   matching). Every description needs a clear role PLUS a trigger clause.
   Accepted phrasings: `Use when…`, `Use this/it/to/for…`, `Use whenever/after/
   before/only/specifically…`, `Activates for/when…`, `Triggers:…`, `Invoke
   when…`, `when the user…`. Prefer the canonical `Use when the user wants to …`.
5. **Overlap** — group skills whose triggers could collide (e.g. networking,
   cannabis, web build/deploy, game art) and note which would win ambiguous matches.

Output a short table: skill | issue | suggested fix. End with a ranked list of
the top merge/cleanup opportunities.
