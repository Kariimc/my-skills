---
name: skill-ship
description: >-
  The control-plane doctor and shipper for this skills repo — add or change a
  skill, rule, hook, or command correctly in one prompt, with no drift left
  behind. Validates frontmatter, de-collides triggers, reconciles README counts,
  lints hooks, syncs to ~/.claude, verifies the change is actually live, then
  commits. Use when the user wants to add, change, fix, or ship a skill / rule /
  hook / command in this control repo, or to doctor the repo for drift (stale
  counts, trigger-less skills, broken sync, colliding triggers).
metadata:
  origin: authored
  family: ultimate-harness
tools: Read, Write, Edit, Bash, Grep, Glob, Task
---

# skill-ship — the control-plane doctor

The 7th, meta-harness: it governs the repo that ships the other six. The whole
month's recurring pain was **control-plane drift** — you change one skill and
something downstream silently falls out of sync (counts, triggers, overlaps, the
catalog, the sync itself, whether it's even live). The piecemeal tools exist
(`skill-audit`, `skill-comply`, `sync-skills`, `config-gc`, `repo-scan`) but
nobody runs all of them after every change. This skill is the one orchestrator
that runs the whole gauntlet and fixes what it finds — in one prompt.

## When to use
- "Add a skill that does X", "change/fix the Y skill", "ship this rule/hook".
- "Doctor the repo", "is anything drifting?", "are my skills actually live?"

## The one prompt
```
/skill-ship "add a skill that does X"      # author + ship a change
/skill-ship                                # doctor the whole repo, no new work
```

## The pipeline (each step kills a real recurring issue)

1. **Author / locate** — create or edit the target `skills/<name>/SKILL.md`,
   `rules/*.md`, `hooks/*.sh`, or `commands/*.md`. Match folder name to
   frontmatter `name:` exactly.

2. **Validate** — run `bin/skill-doctor.sh`. HARD-fails on missing `SKILL.md`,
   missing `name:`, or name≠folder. Flags any skill missing a "Use when…"
   trigger (won't auto-fire). *Kills: invalid frontmatter, trigger-less skills.*

3. **De-collide** — run `/skill-audit`; if the new trigger overlaps an existing
   skill, narrow descriptions so the primary skill wins. *Kills: trigger
   collisions, the recurring OVERLAP-REPORT churn.*

4. **Reconcile metadata** — `bin/skill-doctor.sh --fix` rewrites the README
   skill/agent counts to the live numbers and regenerates the triage report.
   *Kills: the 386-vs-52-vs-actual count drift.*

5. **Lint hooks** — for any touched `hooks/*.sh`: `bash -n`, and run it against a
   sample stdin payload to confirm it doesn't crash or swallow input (the
   heredoc-steals-stdin trap). *Kills: silent hook bugs.*

6. **Sync + verify live** — run the SessionStart sync, then *prove* the change
   landed in `~/.claude/` and actually fires (skill present; hook registered in
   `~/.claude/settings.json`; router routes a sample prompt). Don't claim it's
   live — show it. *Kills: "is it actually synced?" uncertainty.*

7. **Commit** — commit on the working branch with a clear message. The
   pre-commit guard (`.githooks/pre-commit`) re-runs steps 2 & 4 automatically.
   **Land on `master` only when the user explicitly says so.**

## The standing guard
Steps 2 & 4 also run on every commit via `.githooks/pre-commit`, activated
automatically by the SessionStart hook (`git config core.hooksPath .githooks`).
So even a hand-edit can't commit count drift or a name-mismatched skill — the
fix is permanent, not dependent on remembering to run this skill.

## Engine
`bin/skill-doctor.sh` (check / `--fix`) is the mechanical core, shared with the
guard. Related slices: `skill-audit`, `skill-comply`, `skill-stocktake`,
`sync-skills`, `config-gc`, `repo-scan`, `rules-distill`.
