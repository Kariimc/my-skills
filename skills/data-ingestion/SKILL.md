---
name: data-ingestion
description: >
  Run the full brain ingest in one pass. Use when the user wants to "run
  ingestion," sync everything, or refresh the brain from all sources. Runs
  sync-sessions, sync-ecosystem-data, and sync-curated-content back to back,
  using the ingestion log to avoid gaps and re-ingesting.
---

# data-ingestion

Orchestrates the three sync skills and consolidates their results. Bounded: runs
the three, then stops.

## Paths
Brain dir: $BRAIN_DIR -> brain-paths.json (brain_dir) -> ~/brain.

## Steps
1. Read outputs/ingestion-log.md first. Summarize the last run per source so each
   sync knows its high-water mark — this avoids gaps and double-ingesting.
2. Run, in order, stopping a failing one without aborting the rest:
   1. sync-sessions
   2. sync-ecosystem-data
   3. sync-curated-content
3. Aggregate outcomes into ONE consolidated run entry in
   outputs/ingestion-log.md, headed with the run timestamp and a per-source
   breakdown (counts, new wiki links, skill candidates, gaps/errors).

## Report
One consolidated summary: what's new across all three sources, the full list of
skill candidates, and any source that errored or was skipped (with why). Don't
silently swallow a failed source.
