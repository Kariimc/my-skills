---
name: sync-sessions
description: >
  Pull Claude Code session history into the second brain. Use when the user
  wants to sync/ingest past coding sessions, capture learnings from recent work,
  or "mine my sessions." Scans ~/.claude/projects/, saves keepers to raw/inputs/,
  distills lessons into wiki/, and flags repeated tasks as skill candidates.
---

# sync-sessions

## Paths
Brain dir: $BRAIN_DIR -> brain-paths.json (brain_dir) -> ~/brain.
Skills repo: $SKILLS_REPO -> brain-paths.json (skills_repo).
Sessions live at ~/.claude/projects/.

## Steps
1. Read outputs/ingestion-log.md first. Note which session IDs were already
   ingested so you don't re-pull them.
2. Scan ~/.claude/projects/ for sessions newer than the last run (or all, first
   run). Keep conversations worth saving as reference/training data — real
   problem-solving, decisions, durable context. Skip noise and dead ends.
3. Save each keeper to raw/inputs/ verbatim (own file, named date + short slug).
   Never reorganize existing raw/inputs/.
4. Distill durable learnings into wiki/ (reusable notes, not transcripts), each
   linking back to its raw/inputs/ file. Update wiki/README.md.
5. Any task done 3+ times across sessions -> draft a SKILL.md and scaffold
   <skills_repo>/skills/<name>/ with body line
   "STATUS: candidate -- pending Riimos sign-off". Do not deploy it.
6. Append an ingestion-log entry: session IDs ingested, new wiki links, skill
   candidates, gaps.

## Report
Summarize what was saved and the skill candidates scaffolded. If any session
might be sensitive, flag it and let the user exclude it.
