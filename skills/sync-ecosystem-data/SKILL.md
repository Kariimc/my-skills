---
name: sync-ecosystem-data
description: >
  Pull personal ecosystem data — email export and local files — into the second
  brain. Use when the user wants to ingest a Google Takeout export, sync personal
  data, or capture machine files worth keeping. Saves to raw/ecosystem/ and
  distills to wiki/.
---

# sync-ecosystem-data

## Paths
Brain dir: $BRAIN_DIR -> brain-paths.json (brain_dir) -> ~/brain.

## Manual step (irreducible)
The email export requires the user to run a Google Takeout export — you can't do
it for them. Walk them through it, then continue once the export is downloaded.
Everything else here is automatic.

## Steps
1. Read outputs/ingestion-log.md to see what was ingested before.
2. Email (optional — skip if the user isn't comfortable sharing it): point them
   to https://takeout.google.com -> select Mail -> export. When the file is
   available, ingest it into raw/ecosystem/.
3. Local files: scan the locations the user names (or suggest Documents, Desktop,
   project notes) for files worth ingesting. Save copies to raw/ecosystem/
   unaltered.
4. Distill the reusable signal into wiki/ (link back to raw/ecosystem/). Update
   wiki/README.md. Don't dump raw email/files into the wiki.
5. Append an ingestion-log entry (sources, counts, wiki links, gaps).

## Report
Summarize what was ingested and where. Name the one manual step (the Takeout
export) if it's still pending. Never claim contents of files you couldn't read.
