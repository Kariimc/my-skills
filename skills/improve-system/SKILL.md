---
name: improve-system
description: >
  Audit and improve the second-brain system in one pass. Use when the user wants
  to improve/clean up/maintain the brain, review it for problems, or run the
  improvement loop. Finds issues (contradictions, dead links, stale pages, gaps,
  bloat, repeated tasks), sorts every fix into AUTO-APPROVE / NEEDS SIGN-OFF /
  MORE CONTEXT, and gates risky changes behind a checkbox.
---

# improve-system

Single pass. Reads recent activity, proposes changes, sorts each into one of
three buckets, and only auto-applies the safe ones.

## Paths
Brain dir: $BRAIN_DIR -> brain-paths.json (brain_dir) -> ~/brain.
Skills repo: $SKILLS_REPO -> brain-paths.json (skills_repo).

## Step 1 — Apply last run's approvals first
If a prior outputs/review-*.md exists, read it and apply ONLY items whose box is
checked ("- [x]"). Log each applied item to outputs/change-log.md. Leave
unchecked items as-is.

## Step 2 — Read recent
Recent sessions (~/.claude/projects/), outputs/change-log.md,
outputs/ingestion-log.md, and recent wiki/ + skills changes.

## Step 3 — Find opportunities
Wiki contradictions, broken links, stale pages, coverage gaps, skill-friction
patterns, tasks repeated enough to deserve a skill, bloat worth removing.

## Step 4 — Sort every proposed change into ONE bucket
- AUTO-APPROVE: low-risk fixes (typos, dead links, formatting, reindexing).
  Apply directly, log to outputs/change-log.md.
- NEEDS SIGN-OFF: skill edits, new skill candidates, structural wiki rewrites,
  resolving contradictions. Write to outputs/review-<YYYY-MM-DD>.md as a checkbox
  list ("- [ ] ..."). Do NOT apply.
- MORE CONTEXT: ambiguous calls you can't make alone. Write to
  outputs/needs-context-<YYYY-MM-DD>.md as questions.

## Hard rule
Never modify <skills_repo>/skills/ or the wiki/ root for a NEEDS SIGN-OFF item
without a checked box.

## Report
What you auto-applied, what's waiting in review-<date>.md (count + headlines),
and what's in needs-context-<date>.md. Point to both files by path.
