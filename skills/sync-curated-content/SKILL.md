---
name: sync-curated-content
description: >
  Pull curated external content — saved articles, bookmarks, read-later,
  highlights, newsletters, notes — into the second brain. Use when the user wants
  to sync saved/curated reading, import bookmarks or highlights, or "ingest the
  stuff I've saved." Saves to raw/curated/ and distills to wiki/.
---

# sync-curated-content

> Provenance: spec'd to complete the data-ingestion trio. The source named this
> skill but never defined it, so the source list below is a sensible default —
> adjust it to the tools you actually use.

## Paths
Brain dir: $BRAIN_DIR -> brain-paths.json (brain_dir) -> ~/brain.
Skills repo: $SKILLS_REPO -> brain-paths.json (skills_repo).

## Sources (use whichever apply)
- Browser bookmarks export (HTML)
- Read-later export (Pocket / Instapaper / Matter)
- Highlights export (Readwise / Kindle / Apple Books)
- Saved YouTube / newsletter archive / notes-app export
- A drop folder: raw/curated/_inbox/ — anything dropped there gets processed

## Steps
1. Read outputs/ingestion-log.md. Dedupe against already-ingested URLs/hashes.
2. Ingest new curated items into raw/curated/ unaltered.
3. Distill each item's key takeaway into wiki/ — the reusable point and why it
   was saved — linking back to raw/curated/. Update wiki/README.md.
4. If a research topic recurs 3+ times, propose a skill candidate and scaffold
   <skills_repo>/skills/<name>/ with the candidate marker.
5. Append an ingestion-log entry (sources, counts, URLs/hashes, wiki links).

## Report
Summarize what came in and any skill candidates. Flag duplicates skipped.
